{ linuxKernel, lib, stdenv, ... }:
linuxKernel.manualConfig {
  inherit lib stdenv;
  inherit (linuxKernel.kernels.linux_6_0) src version modDirVersion kernelPatches;
  configfile = ./chromiumos-mediatek.config;
  allowImportFromDerivation = true;
}
