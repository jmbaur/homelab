{ lib, pkgs, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";

      # requires linux >=6.8
      hardware.deviceTree.name = "allwinner/sun50i-h618-orangepi-zero2w.dtb";
      boot.kernelPackages = pkgs.linuxPackages_latest;
    }
    {
      custom.server.enable = true;

      custom.image = {
        installer.targetDisk = "/dev/disk/by-path/platform-4020000.mmc";
        boot.uboot = {
          enable = true;
          bootMedium.type = "mmc";
          kernelLoadAddress = "0x42000000";
        };
      };
    }
  ];
}
