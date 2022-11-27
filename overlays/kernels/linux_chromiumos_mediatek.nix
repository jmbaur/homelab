{ linuxKernel, lib, stdenv, concatText, ... }:
linuxKernel.manualConfig {
  inherit lib stdenv;
  inherit (linuxKernel.kernels.linux_6_0) version src;
  configfile = concatText "chromiumos_mediatek-config" [
    "${./nixos_required.config}"
    "${./chromiumos-mediatek.config}"
  ];
  allowImportFromDerivation = true;
}
