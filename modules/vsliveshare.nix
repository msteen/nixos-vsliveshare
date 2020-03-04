{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.vsliveshare;

  fix-vsliveshare = pkgs.writeShellScriptBin "fix-vsliveshare" ''
    if (( $# >= 1 )); then
      version=$1
    else
      version=$(find ~/.vscode/extensions -mindepth 1 -maxdepth 1 -name 'ms-vsliveshare.vsliveshare-*' -printf '%f' | sort -rV | head -n1)
    fi
    version=''${version/ms-vsliveshare.vsliveshare-/}
    if [[ ! $version =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
      echo "Invalid version '$version'." >&2
      exit 1
    fi

    sha256=$(nix-prefetch -q '
      callPackage ${toString ../pkgs/vsliveshare/default.nix} {
        version = "'"$version"'";
        sha256 = "0000000000000000000000000000000000000000000000000000";
      }') &&
    out=$(nix-build --expr '
      with import <nixpkgs> {};
      callPackage ${toString ../pkgs/vsliveshare/default.nix} {
        version = "'"$version"'";
        sha256 = "'"$sha256"'";
      }') ||
    {
      echo "Failed to build VS Code Live Share version '$version'." >&2
      exit 1
    }

    src=$out/share/vscode/extensions/ms-vsliveshare.vsliveshare
    dst=~/.vscode/extensions/ms-vsliveshare.vsliveshare-$version

    # Remove all previous versions of VS Code Live Share.
    find ~/.vscode/extensions -mindepth 1 -maxdepth 1 -name 'ms-vsliveshare.vsliveshare-*' -exec rm -r {} +

    # Create the extension directory.
    mkdir -p "$dst"

    cd "$src"

    # Copy over executable files and symlink files that should remain unchanged or that are ELF executables.
    executables=()
    while read -rd ''' file; do
      if [[ ! -x $file ]] || file "$file" | grep -wq ELF; then
        mkdir -p "$(dirname "$dst/$file")"
        ln -s "$src/$file" "$dst/$file"
      else
        executables+=( "$file" )
      fi
    done < <(find . -mindepth 1 -type f \( -executable -o -name \*.a -o -name \*.dll -o -name \*.pdb \) -printf '%P\0')
    cp --parents --no-clobber --no-preserve=mode,ownership,timestamps -t "$dst" "''${executables[@]}"
    chmod -R +x "$dst"

    # Copy over the remaining directories and files.
    find . -mindepth 1 -type d -printf '%P\0' |
      xargs -0r mkdir -p
    find . -mindepth 1 ! -type d ! \( -type f \( -executable -o -name \*.a -o -name \*.dll -o -name \*.pdb \) \) -printf '%P\0' |
      xargs -0r cp --parents --no-clobber --no-preserve=mode,ownership,timestamps -t "$dst"
  '';

in {
  options.services.vsliveshare = with types; {
    enable = mkEnableOption "VS Code Live Share extension";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ bash desktop-file-utils xlibs.xprop fix-vsliveshare ];

    services.gnome3.gnome-keyring.enable = true;

    systemd.user.services.auto-fix-vsliveshare = {
      description = "Automatically fix the VS Code Live Share extension";
      path = with pkgs; [ inotify-tools fix-vsliveshare nix-prefetch nix file ];
      script = ''
        mkdir -p ~/.vscode/extensions &&
        while IFS=: read -r name event; do
          if [[ $event == 'CREATE,ISDIR' && $name == .ms-vsliveshare.vsliveshare-* ]]; then
            extension=''${name:1}
          elif [[ $event == 'CLOSE_NOWRITE,CLOSE,ISDIR' && -n $extension && $name == ms-vsliveshare.vsliveshare-* ]]; then
            fix-vsliveshare "$extension"
            extension=
          fi
        done < <(inotifywait -q -m -e CREATE,ISDIR -e CLOSE_NOWRITE,CLOSE,ISDIR --format '%f:%e' ~/.vscode/extensions)
      '';
      wantedBy = [ "default.target" ];
    };
  };
}
