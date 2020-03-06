# Live Share support in Visual Studio Code for NixOS

Experimental support for Live Share in Visual Studio Code for NixOS. The need to modify the extension directory in a destructive way and most updates causing the patch files to no longer apply, makes it unsuitable for inclusion in the main Nixpkgs repository, so it is kept in its own repository until a better solution is found.

## Installation

WARNING: The Live Share extension required .NET Core SDK 3, which is not present within the Nixpkgs channel `nixos-19.09`, so if you are not on Nixpkgs channel `nixos-20.03` or up, it will fail to build with `called without required argument 'dotnet-sdk_3'`. To workaround this issue, there is the `nixpkgsPath` option that allows you to specify the path to the Nixpkgs channel that is to be used to build the extension.

```nix
{
  imports = [
    "${builtins.fetchGit {
      url = "https://github.com/msteen/nixos-vsliveshare.git";
      ref = "refs/heads/master";
    }}"
  ];

  services.vsliveshare = {
    enable = true;
    extensionsDir = "$HOME/.vscode-oss/extensions";
    nixpkgsPath = builtins.fetchGit {
      url = "https://github.com/NixOS/nixpkgs.git";
      ref = "refs/heads/nixos-20.03";
      rev = "61cc1f0dc07c2f786e0acfd07444548486f4153b";
    };
  };
}
```

### Home Manager

```nix
{
  imports = [
    "${builtins.fetchGit {
      url = "https://github.com/msteen/nixos-vsliveshare.git";
      ref = "refs/heads/master";
    }}/modules/vsliveshare/home.nix"
  ];

  services.vsliveshare = {
      enable = true;
      extensionsDir = "$HOME/.vscode-oss/extensions";
      nixpkgsPath = "${builtins.fetchGit {
          url = "https://github.com/NixOS/nixpkgs.git";
          ref = "refs/heads/nixos-20.03";
          rev = "61cc1f0dc07c2f786e0acfd07444548486f4153b";
      }}";
  };
}
```

## Usage

You can manually run `fix-vsliveshare` to fix the current extension within ~/.vscode/extensions (i.e. when installed through vscode's extension management). Or you can have this done automatically whenever a new version is installed with `systemctl --user enable auto-fix-vsliveshare && systemctl --user start auto-fix-vsliveshare`. In both cases you will have to reload the VS Code window to get the fixed Live Share to load. In the case of the auto fixer, note that if you reload too fast (e.g. immediately after the Live Share extension is installed through VS Code's extension manager) then the fix might not have enough time to fully build, so either give it a few seconds or if you were to fast, simply reload the window yet again.

### Older versions

There will be an update that causes the current package to fail to build for that version, e.g. due to structural changes made to the extension. In that case please create an issue here and in the meantime you can [downgrade the Live Share extension](https://github.com/microsoft/vscode/issues/30579#issuecomment-456028574), which will pin the extension that particular version regardless of future updates. Then we can run the fixer by passing it the older version (e.g. `fix-vsliveshare 1.0.1653`) or the older extension directory name (e.g. `fix-vsliveshare ms-vsliveshare.vsliveshare-1.0.1653`).

## Limitations

* The package requires SDK 3, which is only available in Nixpkgs channel `nixos-20.03` and up.

* The things that need patching in the extension's source code so far have been almost consistent, but the structure of the package itself has changed over the versions (e.g. `extension.js -> extension-prod.js`), so these kind of changes might cause the fix to fail in the future.
