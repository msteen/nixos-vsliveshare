{ writeShellScript, lib, coreutils, findutils, inotify-tools, fix-vsliveshare
, extensionsDir }:

writeShellScript "auto-fix-vsliveshare.sh" ''
  PATH=${lib.makeBinPath [ coreutils findutils inotify-tools fix-vsliveshare ]}

  if [[ -e "${extensionsDir}" ]]; then
    # Fix the current extension, if available.
    while read -rd ''' name; do
      # There was a previous extension, so there is more than one.
      if [[ -n $extension ]]; then
        extension=
        break
      fi
      extension=$name
    done < <(find "${extensionsDir}" -mindepth 1 -maxdepth 1 -name 'ms-vsliveshare.vsliveshare-*' -printf '%P\0')

    # There is at least one extension.
    if [[ -v extension ]]; then
      # There is more than one extension.
      if [[ -z $extension ]]; then
        fix-vsliveshare
      # There is one extension, and it is not yet fixed.
      elif [[ ! -e "${extensionsDir}/$extension/dotnet_modules/vsls-agent-wrapped" ]]; then
        fix-vsliveshare "$extension"
      fi
    fi
  else
    mkdir -p "${extensionsDir}" || exit
  fi

  # Fix future extensions.
  while IFS=: read -r name event; do
    if [[ $event == 'CREATE,ISDIR' && $name == .ms-vsliveshare.vsliveshare-* ]]; then
      extension=''${name:1}
    elif [[ $event == 'CLOSE_NOWRITE,CLOSE,ISDIR' && -n $extension && $name == ms-vsliveshare.vsliveshare-* ]]; then
      fix-vsliveshare "$extension"
      extension=
    fi
  done < <(inotifywait -q -m -e CREATE,ISDIR -e CLOSE_NOWRITE,CLOSE,ISDIR --format '%f:%e' "${extensionsDir}")
''
