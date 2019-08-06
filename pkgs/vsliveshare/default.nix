# Baseed on previous attempts of others: https://github.com/NixOS/nixpkgs/issues/41189
{ lib, vscode-utils, autoPatchelfHook, bash, dos2unix, file, makeWrapper, dotnet-sdk
, curl, gcc, icu, libkrb5, libsecret, libunwind, libX11, lttng-ust, openssl, utillinux, zlib
, enableDiagnosticsWorkaround ? false, gccStdenv
}:

with lib;

let
  # https://docs.microsoft.com/en-us/visualstudio/liveshare/reference/linux#install-prerequisites-manually
  libs = [
    # .NET Core
    openssl
    libkrb5
    zlib
    icu

    # Credential Storage
    libsecret

    # NodeJS
    libX11

    # https://github.com/flathub/com.visualstudio.code.oss/issues/11#issuecomment-392709170
    libunwind
    lttng-ust
    curl

    # General
    gcc.cc.lib
    utillinux # libuuid
  ];

  vscode-utils' = if enableDiagnosticsWorkaround
    then vscode-utils.override { stdenv = gccStdenv; }
    else vscode-utils;

in (vscode-utils'.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "vsliveshare";
    publisher = "ms-vsliveshare";
    version = "1.0.614";
    sha256 = "1lmpp18l6y2bkrvzra6x0wd100wyc6lwxk2ki84my9ig00z32a6w";
  };
}).overrideAttrs(attrs: {
  prePatch = ''
    dos2unix out/prod/extension-prod.js
  '';

  patches = [ ./extension-prod.js.patch ];

  buildInputs = attrs.buildInputs ++ libs ++ [ autoPatchelfHook bash dos2unix file makeWrapper ];

  installPhase = attrs.installPhase + ''
    runHook postInstall
  '';

  postInstall = ''
    bash -s <<ENDSUBSHELL
    shopt -s extglob
    cd $out/share/vscode/extensions/ms-vsliveshare.vsliveshare

    # A workaround to prevent the journal filling up due to diagnostic logging.
    ${optionalString enableDiagnosticsWorkaround ''
      gcc -fPIC -shared -ldl -o dotnet_modules/noop-syslog.so ${./noop-syslog.c}
    ''}

    # Normally the copying of the right executables and libraries is done externally at a later time,
    # but we want it done at installation time.
    # FIXME: Surely there is a better way than copying over the shared .NET libraries.
    cp \
      ${dotnet-sdk}/shared/Microsoft.NETCore.App/*/* \
      dotnet_modules/runtimes/linux-x64/!(native) \
      dotnet_modules/runtimes/linux-x64/native/* \
      dotnet_modules/runtimes/unix/lib/netstandard1.3/* \
      dotnet_modules

    # Those we need are already copied over, the rest is just a waste of space.
    rm -r dotnet_modules/runtimes

    # Not all executables and libraries are executable, so make sure that they are.
    find . -type f ! -executable -exec file {} + | grep -w ELF | cut -d ':' -f1 | tr '\n' '\0' | xargs -0r -n1 chmod +x

    # Not all scripts are executed by passing them to a shell, so they need to be executable as well.
    find . -type f -name '*.sh' ! -executable -exec chmod +x {} +

    # Lock the extension downloader.
    touch install-linux.Lock externalDeps-linux.Lock
    ENDSUBSHELL
  '';

  rpath = makeLibraryPath libs;

  postFixup = ''
    root=$out/share/vscode/extensions/ms-vsliveshare.vsliveshare

    # We cannot use `wrapProgram`, because it will generate a relative path,
    # which breaks our workaround that makes the extension directory writable.
    mv $root/dotnet_modules/vsls-agent{,-wrapped}
    makeWrapper $root/dotnet_modules/vsls-agent{-wrapped,} \
      --prefix LD_LIBRARY_PATH : "$rpath" ${optionalString enableDiagnosticsWorkaround ''\
      --set LD_PRELOAD "$root/dotnet_modules/noop-syslog.so"
    ''}
  '';

  meta = {
    description = "Live Share lets you achieve greater confidence at speed by streamlining collaborative editing, debugging, and more in real-time during development";
    homepage = https://aka.ms/vsls-docs;
    license = licenses.unfree;
    maintainers = with maintainers; [ msteen ];
    platforms = [ "x86_64-linux" ];
  };
})
