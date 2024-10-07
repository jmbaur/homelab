{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";

      # See https://linux-sunxi.org/H616#missing_Linux_kernel_driver_support
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
          SYS_BOOTM_LEN = freeform "0x${lib.toHexString (64 * 1024 * 1024)}"; # 64MiB

          BOOTCOUNT_LIMIT = yes;
          BOOTCOUNT_ENV = yes;

          # Some settings only enabled if we use DISTRO_DEFAULTS that we must
          # enable manually. See https://github.com/u-boot/u-boot/blob/9cfe0cab3bf135a505e1e163ca442a4e4064d58e/arch/arm/Kconfig#L1150
          CMD_USB = yes;
          USB = yes;
          USB_KEYBOARD = yes;
          USB_STORAGE = yes;
        };
      };

      environment.systemPackages = [
        pkgs.uboot-env-tools
        pkgs.mtdutils
        (pkgs.writeShellScriptBin "update-firmware" ''
          ${lib.getExe' pkgs.mtdutils "flashcp"} \
            --verbose \
            ${config.system.build.firmware}/u-boot-sunxi-with-spl.bin \
            /dev/mtd0
        '')
      ];

      # NOTE: The default env offset is 0xf0000, which only leaves 960KiB for
      # the uboot build to fit on SPI flash. As of 2024-10-03, the uboot build
      # is only ~884KiB, but this is something to keep track of over time.
      environment.etc."fw_env.config".text = ''
        /dev/mtd0 0xf0000 0x10000
      '';
    }
    {
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.nativeBuild = true;
      custom.image = {
        installer.targetDisk = "/dev/disk/by-path/platform-4020000.mmc";
        boot.uefi.enable = true;
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
