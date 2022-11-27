{ linuxKernel, lib, stdenv, ... }:
linuxKernel.manualConfig {
  inherit lib stdenv;
  inherit (linuxKernel.kernels.linux_6_0) version src;
  configfile = ./chromiumos-mediatek.config;
  allowImportFromDerivation = true;
}
