{ lib, stdenv, linuxKernel, u-rootInitramfs, runCommand, buildPackages, dtbFile ? null, ... }:
let
  kernel = (linuxKernel.manualConfig {
    inherit lib stdenv;
    inherit (linuxKernel.kernels.linux_6_0) src version modDirVersion kernelPatches extraMakeFlags;
    configfile = ./linuxboot-${stdenv.hostPlatform.linuxArch}.config;
    config.DTB = true;
  }).overrideAttrs (old: {
    preConfigure = lib.optionalString
      (stdenv.hostPlatform.system == "x86_64-linux")
      "cp ${u-rootInitramfs}/initramfs.cpio /tmp/initramfs.cpio";
    passthru = old.passthru // { initramfs = u-rootInitramfs; };
  });
  fitimage = runCommand "linuxboot-fitimage" { } ''
    mkdir -p $out
    export PATH=${buildPackages.dtc}/bin:$PATH
    ${buildPackages.xz}/bin/lzma --threads 0 <${kernel}/Image >Image.lzma
    cp $(find ${kernel}/dtbs -type f -name ${dtbFile}) target.dtb
    ${buildPackages.xz}/bin/xz --check=crc32 --lzma2=dict=512KiB <${u-rootInitramfs}/initramfs.cpio >initramfs.cpio.xz
    cp ${./linuxboot.its} image.its
    ${buildPackages.ubootTools}/bin/mkimage -f image.its $out/uImage
  '';
in
if
  stdenv.hostPlatform.system == "x86_64-linux" then kernel
else if
  stdenv.hostPlatform.system == "aarch64-linux" then fitimage.overrideAttrs (_: { passthru = { inherit kernel; }; })
else
  throw "unsupported architecture for linuxboot"
