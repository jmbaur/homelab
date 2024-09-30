{ lib, pkgs, ... }:
{
  config = lib.mkMerge [
    {
      nixpkgs.hostPlatform = "aarch64-linux";
      hardware.deviceTree.name = "marvell/armada-8040-mcbin.dtb";
      system.build.firmware = pkgs.mcbin-firmware.override {
        uboot-mvebu_mcbin-88f8040 = pkgs.uboot-mvebu_mcbin-88f8040.override {
          extraStructuredConfig = with lib.kernel; {
            DISTRO_DEFAULTS = unset;
            BOOTSTD_DEFAULTS = yes;

            # Allow for using u-boot scripts.
            BOOTSTD_FULL = yes;

            # Allow for larger than the default 8MiB kernel size
            SYS_BOOTM_LEN = freeform "0x${lib.toHexString (12 * 1024 * 1024)}"; # 12MiB
          };
        };
      };
    }
    {
      custom.image = {
        boot.uefi.enable = true;
        installer.targetDisk = "/dev/nvme0n1"; # TODO(jared): be more specific
      };
      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.nativeBuild = true;
    }
    {
      services.navidrome = {
        enable = true;
        settings = {
          Address = "[::]";
          Port = 4533;
          DefaultTheme = "Auto";
        };
      };
    }
    {
      services.photoprism = {
        enable = true;
        address = "[::]";
        originalsPath = "/data/photos";
      };
    }
    {
      services.jellyfin.enable = true;
    }
  ];
}
