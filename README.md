# Live Share support in Visual Studio Code for NixOS

Experimental support for Live Share in Visual Studio Code for NixOS. The need to modify the extension directory in a destructive way and most updates causing the patch files to no longer apply, makes it unsuitable for inclusion in the main Nixpkgs repository, so it is kept in its own repository until a better solution is found.

## Installation

```nix
{
  imports = [
    "${builtins.fetchGit {
      url = "https://github.com/msteen/nixos-vsliveshare.git";
      ref = "refs/heads/master";
    }}"
  ];

  services.vsliveshare.enable = true;
}
```

## Usage

You can manually run `fix-vsliveshare` to fix the current extension within ~/.vscode/extensions (i.e. when installed through vscode's extension management). Or you can have this done automatically whenever a new version is installed with `systemctl --user enable auto-fix-vsliveshare && systemctl --user start auto-fix-vsliveshare`. In both cases you will have to reload the VS Code window to get the fixed Live Share to load. In the case of the auto fixer, note that if you reload too fast (e.g. immediately after the Live Share extension is installed through VS Code's extension manager) then the fix might not have enough time to fully build, so either give it a few seconds or if you were to fast, simply reload the window yet again.

It is also possible to install an older version again, if for some reason a later version breaks, by passing the version (e.g. `fix-vsliveshare 1.0.614`) or the extension directory name (e.g. `fix-vsliveshare ms-vsliveshare.vsliveshare-1.0.1653`).

## Limitations

* The auto fixer is very experimental, I tested it once with an old version of Live Share present (i.e. an actual update) and the rest of the time through fresh installs, so the might still be some remaining bugs in the mechanism.

* The things that need patching in the extension's source code so far have been almost consistent, but the structure of the package itself has changed over the versions (e.g. `extension.js -> extension-prod.js`), so these kind of changes might cause the fix to fail for later versions.

* I have only tested this under `nixos-20.03`.
