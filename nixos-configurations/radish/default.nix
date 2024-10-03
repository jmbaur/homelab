{ lib, pkgs, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";

      # requires linux >= 6.8
      hardware.deviceTree.name = "allwinner/sun50i-h618-orangepi-zero3.dtb";
      boot.kernelPackages = pkgs.linuxPackages_latest;

      system.build.firmware = pkgs.uboot-orangepi_zero3.override {
        extraStructuredConfig = with lib.kernel; {
          DISTRO_DEFAULTS = unset;
          BOOTSTD_DEFAULTS = yes;
          FIT = yes;

          # Allow for using u-boot scripts.
          BOOTSTD_FULL = yes;

          # Allow for larger than the default 8MiB kernel size
          SYS_BOOTM_LEN = freeform "0x${lib.toHexString (12 * 1024 * 1024)}"; # 12MiB

          BOOTCOUNT_LIMIT = yes;
          BOOTCOUNT_ENV = yes;
        };
      };
    }
    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      # custom.nativeBuild = true;
      custom.image = {
        installer.targetDisk = "/dev/disk/by-path/platform-4020000.mmc";
        boot.uboot = {
          enable = true;
          bootMedium.type = "mmc";
          kernelLoadAddress = "0x46000000";
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
