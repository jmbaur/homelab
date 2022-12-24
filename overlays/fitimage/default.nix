{ runCommand, ubootTools, dtc, xz, ... }:
{ boardName
, kernel
, dtb ? ./qemu-aarch64.dtb
, initramfs
}:
runCommand "fitimage-${boardName}" { nativeBuildInputs = [ ubootTools dtc xz ]; } ''
  mkdir -p $out
  lzma --threads 0 <${kernel}/Image >Image.lzma
  xz --test <${initramfs}
  cp ${initramfs} initramfs.cpio.xz
  cp ${dtb} target.dtb
  cp ${./image.its} image.its
  mkimage -f image.its $out/uImage
''
