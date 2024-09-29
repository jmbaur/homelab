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

      custom.nativeBuild = true;

      custom.image = {
        installer.targetDisk = "/dev/disk/by-path/TODO";
        boot.uboot = {
          enable = true;
          bootMedium.type = "mmc";
          kernelLoadAddress = "0x0"; # TODO
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
          pipewireSupport = false; # TODO(jared): get this working
        };
      };
    }
  ];
}
