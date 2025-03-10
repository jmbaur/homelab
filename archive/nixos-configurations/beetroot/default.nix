{ lib, pkgs, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";

      # requires linux >=6.8
      hardware.deviceTree.name = "allwinner/sun50i-h618-orangepi-zero2w.dtb";
      boot.kernelPackages = pkgs.linuxPackages_latest;

      hardware.firmware = [
        pkgs.wireless-regdb
        pkgs.orangepi-firmware
      ];
    }
    {
      custom.server.enable = true;
      custom.recovery.targetDisk = "/dev/disk/by-path/platform-4020000.mmc";
    }
  ];
}
