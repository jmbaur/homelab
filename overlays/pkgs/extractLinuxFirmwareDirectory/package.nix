{ runCommand, linux-firmware }:

directory:

runCommand "${directory}-linux-firmware" { } ''
  mkdir -p $out/lib/firmware/${directory}
  cp -r ${linux-firmware}/lib/firmware/${directory}/* $out/lib/firmware/${directory}

  # Find and fix broken symlinks
  while read -r symlink; do
    resolved=$(readlink --canonicalize-missing $symlink)
    if [[ -f $resolved ]]; then
      continue
    fi

    install -Dm0444 ''${resolved/$out/${linux-firmware}} $out''${resolved/$out/}
  done < <(find $out/lib/firmware -type l)
''
