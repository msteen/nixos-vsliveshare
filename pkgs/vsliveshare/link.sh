#!/usr/bin/env bash
out=/nix/store/1lhpmk7amqy7zfldqg26lcp3k8x91y3j-vscode-extension-ms-vsliveshare-vsliveshare-0.3.954
src=$out/share/vscode/extensions/ms-vsliveshare.vsliveshare

dst=~/.vscode/extensions/ms-vsliveshare.vsliveshare-$(basename $out | sed 's/.*vsliveshare-//')

# Only run the script when the build has actually changed.
# if [[ $(dirname "$(dirname "$(readlink "${dst}/dotnet_modules/vsls-agent-wrapped")")") == $src ]]; then
#   exit 0
# fi

# Remove all previous versions of VS Code Live Share.
rm -r ~/.vscode/extensions/ms-vsliveshare.vsliveshare*

# Create the extension directory.
mkdir -p "$dst"

# Symlink files which should remain unchanged.
find $src -type f \( -name \*.a -o -name \*.dll -o -name \*.pdb \) | while read -r src_file; do
  dst_file="${dst}${src_file#${src}}"
  mkdir -p $(dirname "$dst_file")
  ln -s "$src_file" "$dst_file"
done

# Symlink ELF executables and copy over executable files.
find $src -type f -executable | while read -r src_file; do
  dst_file="${dst}${src_file#${src}}"
  mkdir -p $(dirname "$dst_file")
  if file "$src_file" | grep -wq ELF; then
    ln -s "$src_file" "$dst_file"
  else
    cp --no-preserve=mode,ownership,timestamps "$src_file" "$dst_file"
    chmod +x "$dst_file"
  fi
done

# Copy over the remaining files and directories.
# FIXME: Use a different command that does not warn about files being the same.
cp -r --no-clobber --no-preserve=mode,ownership,timestamps "$src/." "$dst" 2> >(grep -Ev "^cp: '.*' and '.*' are the same file$")
exit 0
