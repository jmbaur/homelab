{ lib, linuxManualConfig, linuxPackages_latest, stdenv, ... }:
linuxManualConfig {
  inherit lib stdenv;
  # follow latest kernel from nixpkgs for best hardware support
  inherit (linuxPackages_latest.kernel) src version modDirVersion kernelPatches extraMakeFlags;
  configfile = ./linuxboot-${stdenv.hostPlatform.linuxArch}.config;
  config.DTB = stdenv.hostPlatform.system != "x86_64-linux";
}
