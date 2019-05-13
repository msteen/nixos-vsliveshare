#!/usr/bin/env bash
out=/nix/store/acj5pr3bj0v19f9a4d1x1psly35fvml6-vscode-extension-ms-vsliveshare-vsliveshare-0.3.954
for out in $(nix-store -qR $out); do
  if find $out -type f -exec strings {} + | grep -q '/dev/log'; then
    echo $out
  fi
done
