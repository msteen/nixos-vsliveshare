# Live Share support in Visual Studio Code for NixOS

Experimental support for Live Share in Visual Studio Code for NixOS. The need to modify the extension directory in a destructive way and most updates causing the patch files to no longer apply, makes it unsuitable for inclusion in the main Nixpkgs repository, so it is kept in its own repository until a better solution is found.

```nix
{ ... }:

{
  imports = [
    (builtins.fetchTarball {
      sha256 = "1qmq5zwd4qdxdxh4zxc7yr7qwajgnsjdw2npw0rfkyahmrqw3j02";
      url = "https://github.com/msteen/nixos-vsliveshare/archive/86624fe317c24df90e9451dd5741220c98d2249d.tar.gz";
    })
  ];

  services.vsliveshare = {
    enable = true;
    enableWritableWorkaround = true;
    enableDiagnosticsWorkaround = true;
    extensionsDir = "/home/matthijs/.vscode/extensions";
  };
}
```
