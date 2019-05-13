{ ... }:

{
  imports = [
    ./modules/vsliveshare.nix
  ];

  nixpkgs.overlays = [
    (import ./pkgs/overlay.nix)
  ];
}
