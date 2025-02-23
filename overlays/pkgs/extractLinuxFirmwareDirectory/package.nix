{ runCommand, linux-firmware }:

directory:

runCommand "${directory}-linux-firmware" { } ''
  mkdir -p $out/lib/firmware/${directory}
  cp -r ${linux-firmware}/lib/firmware/${directory}/* $out/lib/firmware/${directory}
''
