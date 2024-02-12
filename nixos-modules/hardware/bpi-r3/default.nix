{ config, lib, pkgs, ... }: {
  options.hardware.bpi-r3 = {
    enable = lib.mkEnableOption "bananapi r3";
  };

  config = lib.mkIf config.hardware.bpi-r3.enable {
    boot.kernelPackages = pkgs.linuxPackages_6_7;
    boot.kernelPatches = [
      {
        name = "mt7986a-enablement";
        patch = null;
        extraStructuredConfig = with lib.kernel; {
          BRIDGE = yes;
          HSR = yes;
          MEDIATEK_GE_PHY = yes;
          MTD_NAND_ECC_MEDIATEK = yes;
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
          url = "https://raw.githubusercontent.com/openwrt/openwrt/dfc1e8cfeea51106b988cd2a924644976ad01fe7/target/linux/mediatek/patches-6.1/195-dts-mt7986a-bpi-r3-leds-port-names-and-wifi-eeprom.patch";
          hash = "sha256-MsbWYPITxLvjAGRLIXC0j0+xAJdmMocic3N47DZ+GUs=";
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
      overlays = map
        (dtboFile: {
          inherit dtboFile;
          name = builtins.baseNameOf dtboFile;
        }) [
        "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-nand.dtbo"
        "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-emmc.dtbo"
      ];
    };

    environment.systemPackages = with pkgs; [ mtdutils ubootEnvTools ];

    boot.kernelModules = [ "ubi" ];
    boot.extraModprobeConfig = ''
      options ubi mtd=ubi
    '';

    # for fw_printenv and fw_setenv
    environment.etc."fw_env.config".text = ''
      # UBI volume            Device offset   Env. size       Flash sector size       Number of sectors
      /dev/ubi0:ubootenv      0x0             0x1f000         0x1f000
      /dev/ubi0:ubootenvred   0x0             0x1f000         0x1f000
    '';

    # https://github.com/torvalds/linux/blob/841c35169323cd833294798e58b9bf63fa4fa1de/include/uapi/linux/input-event-codes.h#L481
    # bpi-r3 uses KEY_RESTART
    # KEY_RESTART == 0x198 == 408
    systemd.services.reset-button = {
      description = "Restart the system when the reset button is pressed";
      unitConfig.ConditionPathExists = [ "/dev/input/by-path/platform-gpio-keys-event" ];
      # make sure evsieve button identifiers are escaped
      serviceConfig.ExecStart = lib.replaceStrings [ "%" ] [ "%%" ]
        (toString [
          (lib.getExe' pkgs.evsieve "evsieve")
          # TODO(jared): confirm this path
          "--input /dev/input/by-path/platform-gpio-keys-event"
          "--hook btn:%408 exec-shell=\"systemctl reboot\""
        ]);
      wantedBy = [ "multi-user.target" ];
    };

    system.build = {
      uboot = (pkgs.uboot-mt7986a_bpir3_emmc.override {
        extraStructuredConfig = with pkgs.ubootLib; {
          AHCI = yes;
          AHCI_PCI = yes;
          AUTOBOOT = yes;
          BOOTCOUNT_ENV = yes;
          BOOTCOUNT_LIMIT = yes;
          BOOTSTD_DEFAULTS = yes;
          BOOTSTD_FULL = yes;
          CMD_MTD = yes;
          CMD_SCSI = yes;
          CMD_UBI = yes;
          CMD_USB = yes;
          DM_MTD = yes;
          DM_SCSI = yes;
          DM_SPI = yes;
          DM_USB = yes;
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
          PCI = yes;
          PCIE_MEDIATEK = yes;
          PHY = yes;
          PHY_FIXED = yes;
          PHY_MTK_TPHY = yes;
          SCSI = yes;
          SCSI_AHCI = yes;
          SPI = yes;
          SUPPORT_EMMC_BOOT = yes;
          SYS_REDUNDAND_ENVIRONMENT = yes;
          USB = yes;
          USB_HOST = yes;
          USB_STORAGE = yes;
          USB_XHCI_HCD = yes;
          USB_XHCI_MTK = yes;
          USE_BOOTCOMMAND = yes;
        };
      }).overrideAttrs ({ patches ? [ ], ... }: {
        patches = patches ++ [ ./mt7986-persistent-mac-from-cpu-uid.patch ];
      });

      firmware = pkgs.callPackage ./firmware.nix {
        uboot-mt7986a_bpir3_emmc = config.system.build.uboot;
      };
    };
  };
}
