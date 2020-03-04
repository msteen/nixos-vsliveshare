moduleConfig:
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.vsliveshare;

  fix-vsliveshare = pkgs.callPackage ../../pkgs/fix-vsliveshare { inherit (cfg) extensionsDir; };

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
  };

  config = mkIf cfg.enable (moduleConfig rec {
    packages = with pkgs; [ bash desktop-file-utils xlibs.xprop fix-vsliveshare ];
    name = "auto-fix-vsliveshare";
    description = "Automatically fix the VS Code Live Share extension";
    script = pkgs.writeShellScript "${name}.sh" ''
      PATH=${makeBinPath (with pkgs; [ coreutils inotify-tools fix-vsliveshare ])}
      mkdir -p "${cfg.extensionsDir}" &&
      while IFS=: read -r name event; do
        if [[ $event == 'CREATE,ISDIR' && $name == .ms-vsliveshare.vsliveshare-* ]]; then
          extension=''${name:1}
        elif [[ $event == 'CLOSE_NOWRITE,CLOSE,ISDIR' && -n $extension && $name == ms-vsliveshare.vsliveshare-* ]]; then
          fix-vsliveshare "$extension"
          extension=
        fi
      done < <(inotifywait -q -m -e CREATE,ISDIR -e CLOSE_NOWRITE,CLOSE,ISDIR --format '%f:%e' "${cfg.extensionsDir}")
    '';
  });
}
