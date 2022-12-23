{ lib
, stdenv
, linuxKernel
, u-rootInitramfs
, runCommand
, ubootTools
, dtc
, xz
, dtb ? ./qemu-aarch64.dtb
, ...
}:
let
  kernel = (linuxKernel.manualConfig {
    inherit lib stdenv;
    inherit (linuxKernel.kernels.linux_6_0) src version modDirVersion kernelPatches extraMakeFlags;
    configfile = ./linuxboot-${stdenv.hostPlatform.linuxArch}.config;
    config.DTB = stdenv.hostPlatform.system != "x86_64-linux";
  }).overrideAttrs (old: {
    preConfigure = lib.optionalString
      (stdenv.hostPlatform.system == "x86_64-linux")
      "cp ${u-rootInitramfs}/initramfs.cpio /tmp/initramfs.cpio";
    passthru = old.passthru // { initramfs = u-rootInitramfs; };
  });

  fitimage = runCommand "linuxboot-fitimage" { nativeBuildInputs = [ ubootTools dtc xz ]; } ''
    mkdir -p $out
    lzma --threads 0 <${kernel}/Image >Image.lzma
    xz --check=crc32 --lzma2=dict=512KiB <${u-rootInitramfs}/initramfs.cpio >initramfs.cpio.xz
    ${if (builtins.isString dtb) then ''
    cp $(find ${kernel}/dtbs -type f -name ${dtb}) target.dtb
    '' else if (builtins.isPath dtb) then ''
    cp ${dtb} target.dtb
    '' else throw "unsupported dtb"}
    cp ${./linuxboot.its} image.its # the ITS file needs to be in the same directory as the files it will use
    mkimage -f image.its $out/uImage
  '';
in
if
  stdenv.hostPlatform.system == "x86_64-linux" then kernel
else if
  stdenv.hostPlatform.system == "aarch64-linux" then fitimage.overrideAttrs (_: { passthru = { inherit kernel; }; })
else
  throw "unsupported system"
