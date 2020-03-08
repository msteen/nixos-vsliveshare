moduleConfig:
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.vsliveshare;

  fix-vsliveshare = pkgs.callPackage ../../pkgs/fix-vsliveshare { inherit (cfg) extensionsDir nixpkgsPath; };

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

  config = mkIf cfg.enable (moduleConfig rec {
    packages = with pkgs; [ bash desktop-file-utils xlibs.xprop fix-vsliveshare ];
    name = "auto-fix-vsliveshare";
    description = "Automatically fix the VS Code Live Share extension";
    script = pkgs.writeShellScript "${name}.sh" ''
      PATH=${makeBinPath (with pkgs; [ coreutils findutils inotify-tools fix-vsliveshare ])}
      if [[ -e "${cfg.extensionsDir}" ]]; then
        # Fix the current extension, if available.
        while read -rd ''' name; do
          # There was a previous extension, so there is more than one.
          if [[ -n $extension ]]; then
            extension=
            break
          fi
          extension=$name
        done < <(find "${cfg.extensionsDir}" -mindepth 1 -maxdepth 1 -name 'ms-vsliveshare.vsliveshare-*' -printf '%P\0')
        # There is at least one extension.
        if [[ -v extension ]]; then
          # There is more than one extension.
          if [[ -z $extension ]]; then
            fix-vsliveshare
          # There is one extension, and it is not yet fixed.
          elif [[ ! -e "${cfg.extensionsDir}/$extension/dotnet_modules/vsls-agent-wrapped" ]]; then
            fix-vsliveshare "$extension"
          fi
        fi
      else
        mkdir -p "${cfg.extensionsDir}" || exit
      fi
      # Fix future extensions.
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
