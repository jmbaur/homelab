{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.hardware.bpi-r3.enable = lib.mkEnableOption "bananapi r3";

  config = lib.mkIf config.hardware.bpi-r3.enable {
    boot.kernelPackages = pkgs.linuxPackages_6_12;
    boot.kernelPatches = [
      {
        name = "mt7986a-enablement";
        patch = null;
        extraStructuredConfig = with lib.kernel; {
          BRIDGE = yes;
          HSR = yes;
          MEDIATEK_GE_PHY = yes;
          MTD_NAND_ECC_MEDIATEK = yes;
          MTD_SPI_NAND = yes;
          MTK_LVTS_THERMAL = yes;
          MTK_SOC_THERMAL = yes;
          MTK_THERMAL = yes;
          NET_DSA = yes;
          NET_DSA_MT7530 = yes;
          NET_DSA_TAG_MTK = yes;
          NET_MEDIATEK_SOC = yes;
          NET_MEDIATEK_STAR_EMAC = yes;
          PCIE_MEDIATEK = yes;
          PCIE_MEDIATEK_GEN3 = yes;
          PCS_MTK_LYNXI = yes;
          REGULATOR_MT6380 = yes;
        };
      }
      {
        name = "mt7986a-wifi";
        patch = pkgs.fetchpatch {
          url = "https://raw.githubusercontent.com/openwrt/openwrt/06b37a5856ac7d0a2ddc2c0745ac1da3a01688d6/target/linux/mediatek/patches-6.6/195-dts-mt7986a-bpi-r3-leds-port-names-and-wifi-eeprom.patch";
          excludes = [ "arch/arm64/boot/dts/mediatek/mt7986a-bananapi-bpi-r3-nor.dtso" ]; # doesn't apply cleanly
          hash = "sha256-saqnN7A8nUYPLl7JtC6BEljmb+rmuUcgDIXTb3s55UE=";
        };
      }
    ];

    # needed for mediatek firmware
    hardware.firmware = [ pkgs.linux-firmware ];

    boot.kernelParams = [ "console=ttyS0,115200" ];

    # u-boot looks for $fdtfile on the ESP at /dtb
    boot.loader.systemd-boot.extraFiles."dtb" = config.hardware.deviceTree.package;
    boot.loader.grub.extraFiles."dtb" = config.hardware.deviceTree.package;

    hardware.deviceTree = {
      enable = true;
      name = "mediatek/mt7986a-bananapi-bpi-r3.dtb";
      overlays =
        map
          (dtboFile: {
            inherit dtboFile;
            name = builtins.baseNameOf dtboFile;
          })
          [
            "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-nand.dtbo"
            "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-emmc.dtbo"
          ];
    };

    environment.systemPackages = with pkgs; [
      mtdutils
      uboot-env-tools
    ];

    boot.kernelModules = [ "ubi" ];
    boot.extraModprobeConfig = ''
      options ubi mtd=ubi
    '';

    environment.etc."fw_env.config".text = ''
      /dev/ubi0:ubootenv    0x0 0x1f000 0x1f000
      /dev/ubi0:ubootenvred 0x0 0x1f000 0x1f000
    '';

    # https://github.com/torvalds/linux/blob/841c35169323cd833294798e58b9bf63fa4fa1de/include/uapi/linux/input-event-codes.h#L481
    # bpi-r3 uses KEY_RESTART
    # KEY_RESTART == 0x198 == 408
    systemd.services.reset-button = {
      description = "Restart the system when the reset button is pressed";
      unitConfig.ConditionPathExists = [ "/dev/input/by-path/platform-gpio-keys-event" ];
      # make sure evsieve button identifiers are escaped
      serviceConfig.ExecStart = lib.replaceStrings [ "%" ] [ "%%" ] (toString [
        (lib.getExe' pkgs.evsieve "evsieve")
        "--input /dev/input/by-path/platform-gpio-keys-event"
        "--hook btn:%408 exec-shell=\"systemctl reboot\""
      ]);
      wantedBy = [ "multi-user.target" ];
    };

    system.build = {
      uboot =
        (pkgs.uboot-mt7986a_bpir3_emmc.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./mt7986-persistent-mac-from-cpu-uid.patch ];
        })).override
          {
            extraStructuredConfig = with lib.kernel; {
              AHCI = yes;
              AHCI_PCI = yes;
              AUTOBOOT = yes;
              BLK = yes;
              BOOTCOUNT_ENV = yes;
              BOOTCOUNT_LIMIT = yes;
              BOOTMETH_EFI_BOOTMGR = yes;
              BOOTSTD_DEFAULTS = yes;
              BOOTSTD_FULL = yes;
              CMD_BOOTEFI = yes;
              CMD_MTD = yes;
              CMD_SCSI = yes;
              CMD_UBI = yes;
              CMD_USB = yes;
              DM_MTD = yes;
              DM_SCSI = yes;
              DM_SPI = yes;
              DM_USB = yes;
              EFI_BOOTMGR = yes;
              EFI_LOADER = yes;
              ENV_IS_IN_MMC = unset;
              ENV_IS_IN_UBI = yes;
              ENV_OFFSET = unset;
              ENV_SIZE = freeform "0x1f000";
              ENV_SIZE_REDUND = freeform "0x1f000";
              ENV_UBI_PART = freeform "ubi";
              ENV_UBI_VOLUME = freeform "ubootenv";
              ENV_UBI_VOLUME_REDUND = freeform "ubootenvred";
              ENV_VARS_UBOOT_RUNTIME_CONFIG = yes;
              FIT = yes;
              MTD = yes;
              MTD_SPI_NAND = yes;
              MTK_AHCI = yes;
              MTK_SPIM = yes;
              PARTITIONS = yes;
              PCI = yes;
              PCIE_MEDIATEK = yes;
              PHY = yes;
              PHY_FIXED = yes;
              PHY_MTK_TPHY = yes;
              SCSI = yes;
              SCSI_AHCI = yes;
              SPI = yes;
              SUPPORT_EMMC_BOOT = yes;
              SYS_BOOTM_LEN = freeform "0x${lib.toHexString (128 * 1024 * 1024)}";
              SYS_REDUNDAND_ENVIRONMENT = yes;
              USB = yes;
              USB_HOST = yes;
              USB_STORAGE = yes;
              USB_XHCI_HCD = yes;
              USB_XHCI_MTK = yes;
              USE_BOOTCOMMAND = yes;
            };
          };

      firmware = pkgs.callPackage ./firmware.nix {
        uboot-mt7986a_bpir3_emmc = config.system.build.uboot;
      };
    };
  };
}
