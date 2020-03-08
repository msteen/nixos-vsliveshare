moduleConfig:
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.vsliveshare;

  fix-vsliveshare = pkgs.callPackage ../../pkgs/fix-vsliveshare {
    inherit (cfg) extensionsDir nixpkgsPath;
  };

in {
  options.services.vsliveshare = with types; {
    enable = mkEnableOption "VS Code Live Share extension";

    extensionsDir = mkOption {
      type = str;
      default = "$HOME/.vscode/extensions";
      description = ''
        The VS Code extensions directory.
        CAUTION: The fix will remove ms-vsliveshare.vsliveshare-* inside this directory!
      '';
    };

    nixpkgsPath = mkOption {
      type = coercedTo path toString str;
      default = "<nixpkgs>";
      description = ''
        The extension is likely to need the latest dependencies (e.g. nixos-unstable),
        while your system might still be running under an older Nixpkgs (e.g. one of the stable nixos channels),
        so this option allows you to specify which Nixpkgs should be using for the building of the extension.
      '';
    };
  };

  config = mkIf cfg.enable (moduleConfig {
    packages = with pkgs; [ bash desktop-file-utils xlibs.xprop fix-vsliveshare ];
    description = "Automatically fix the VS Code Live Share extension";
    script = "${pkgs.callPackage ../../pkgs/auto-fix-vsliveshare {
      inherit fix-vsliveshare;
      inherit (cfg) extensionsDir;
    }}";
  });
}
