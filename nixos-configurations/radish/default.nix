{ lib, pkgs, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";

      # requires linux >= 6.8
      hardware.deviceTree.name = "allwinner/sun50i-h618-orangepi-zero3.dtb";
      boot.kernelPackages = pkgs.linuxPackages_latest;
    }
    {
      custom.server.enable = true;
      custom.basicNetwork = true;
      custom.nativeBuild = true;
      custom.image = {
        installer.targetDisk = "/dev/disk/by-path/platform-4020000.mmc";
        boot.uboot = {
          enable = true;
          bootMedium.type = "mmc";
          kernelLoadAddress = "0x42000000";
        };
      };
    }
    {
      services.xserver.desktopManager.kodi = {
        enable = true;
        package = pkgs.kodi.override {
          sambaSupport = false; # deps don't cross-compile
          x11Support = false;
          waylandSupport = true;
          pipewireSupport = true;
        };
      };
    }
  ];
}
