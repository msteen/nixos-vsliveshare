{ writeShellScriptBin, lib, coreutils, findutils, nix-prefetch, nix, file, gnugrep, jq
, extensionsDir }:

writeShellScriptBin "fix-vsliveshare" ''
  PATH=${lib.makeBinPath [ coreutils findutils nix-prefetch nix file gnugrep jq ]}

  if (( $# >= 1 )); then
    version=$1
  else
    version=$(find "${extensionsDir}" -mindepth 1 -maxdepth 1 -name 'ms-vsliveshare.vsliveshare-*' -printf '%f' | sort -rV | head -n1)
  fi
  version=''${version/ms-vsliveshare.vsliveshare-/}
  if [[ ! $version =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "Invalid version '$version'." >&2
    exit 1
  fi

  sha256=$(nix-prefetch -q '
    callPackage ${toString ../vsliveshare} {
      version = "'"$version"'";
      sha256 = "0000000000000000000000000000000000000000000000000000";
    }') &&
  out=$(nix-build --expr '
    with import <nixpkgs> {};
    callPackage ${toString ../vsliveshare} {
      version = "'"$version"'";
      sha256 = "'"$sha256"'";
    }') ||
  {
    echo "Failed to build VS Code Live Share version '$version'." >&2
    exit 1
  }

  src=$out/share/vscode/extensions/ms-vsliveshare.vsliveshare
  dst="${extensionsDir}"/ms-vsliveshare.vsliveshare-$version

  # Remove all previous versions of VS Code Live Share.
  find "${extensionsDir}" -mindepth 1 -maxdepth 1 -name 'ms-vsliveshare.vsliveshare-*' -exec rm -r {} +

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

  # Make sure the version is not marked obsolete, otherwise vscode won't load the extension.
  [[ -e "${extensionsDir}"/.obsolete ]] &&
  obsolete_json=$(< "${extensionsDir}"/.obsolete) &&
  jq 'del(."'"$(basename "$dst")"'")' <<< "$obsolete_json" > "${extensionsDir}"/.obsolete || true
''
