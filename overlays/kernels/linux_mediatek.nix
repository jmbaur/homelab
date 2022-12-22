{ linuxKernel, lib, stdenv, ... }:
linuxKernel.manualConfig {
  inherit lib stdenv;
  inherit (linuxKernel.kernels.linux_6_1) src version modDirVersion kernelPatches extraMakeFlags;
  configfile = ./mediatek.config;
  config.DTB = stdenv.hostPlatform.system != "x86_64-linux";
}
