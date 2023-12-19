{ boardName, kernel, initrd, dtbsDir, }:
{ runCommand, ubootTools, dtc, xz, rsync, ... }:
runCommand "fitimage-${boardName}" { nativeBuildInputs = [ rsync ubootTools dtc xz ]; } ''
  lzma --threads 0 <${kernel} >kernel.lzma
  bash ${./make-image-its.bash} kernel.lzma ${initrd} ${dtbsDir} > image.its
  mkimage -f image.its $out
''

