# Baseed on previous attempts of others: https://github.com/NixOS/nixpkgs/issues/41189
{ lib, vscode-utils, gccStdenv, autoPatchelfHook, bash, dos2unix, file, makeWrapper, dotnet-sdk_3
, curl, gcc, icu, libkrb5, libsecret, libunwind, libX11, lttng-ust, openssl, utillinux, zlib
, version, sha256
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

in ((vscode-utils.override { stdenv = gccStdenv; }).buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "vsliveshare";
    publisher = "ms-vsliveshare";
    inherit version sha256;
  };
}).overrideAttrs(attrs: {
  buildInputs = attrs.buildInputs ++ libs ++ [ autoPatchelfHook bash file makeWrapper ];

  # Using a patch file won't work, because the file changes too often, causing the patch to fail on most updates.
  # Rather than patching the calls to functions, we modify the functions to return what we want,
  # which is less likely to break in the future.
  postPatch = ''
    sed -i \
      -e 's/updateExecutablePermissionsAsync() {/& return;/' \
      -e 's/isInstallCorrupt(traceSource, manifest) {/& return false;/' \
      out/prod/extension-prod.js
  '';

  # Support for the `postInstall` hook was added only in nixos-20.03,
  # so for backwards compatibility reasons lets not use it yet.
  installPhase = attrs.installPhase + ''
    bash -s <<ENDSUBSHELL
    shopt -s extglob
    cd $out/share/vscode/extensions/ms-vsliveshare.vsliveshare

    # FIXME: I think the noop-syslog.so workaround fails due to no longer using a locally copied SDK.
    # A workaround to prevent the journal filling up due to diagnostic logging.
    # See: https://github.com/MicrosoftDocs/live-share/issues/1272

    # Normally the copying of the right executables is done externally at a later time,
    # but we want it done at installation time.
    cp dotnet_modules/exes/linux-x64/* dotnet_modules

    # The other runtimes won't be used and thus are just a waste of space.
    rm -r dotnet_modules/runtimes/!(linux-x64)

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
      --prefix LD_LIBRARY_PATH : "$rpath" \
      --set DOTNET_ROOT ${dotnet-sdk_3}
  '';

  meta = {
    description = "Live Share lets you achieve greater confidence at speed by streamlining collaborative editing, debugging, and more in real-time during development";
    homepage = "https://aka.ms/vsls-docs";
    license = licenses.unfree;
    maintainers = with maintainers; [ msteen ];
    platforms = [ "x86_64-linux" ];
  };
})
