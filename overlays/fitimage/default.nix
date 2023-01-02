{ runCommand, ubootTools, dtc, xz, ... }:
# TODO(jared): handle multiple DTBs
{ boardName, kernel, dtb, initramfs }:
runCommand "fitimage-${boardName}" { nativeBuildInputs = [ ubootTools dtc xz ]; } ''
  mkdir -p $out
  lzma --threads 0 <${kernel}/Image >Image.lzma
  xz --test <${initramfs}
  cp ${initramfs} initramfs.cpio.xz
  cp ${dtb} target.dtb
  cp ${./image.its} image.its
  mkimage -f image.its $out/uImage
''
