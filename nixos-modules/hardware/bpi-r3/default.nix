{ config, lib, pkgs, ... }: {
  options.hardware.bpi-r3 = {
    enable = lib.mkEnableOption "bananapi r3";
  };

  config = lib.mkIf config.hardware.bpi-r3.enable {
    boot.kernelPackages = pkgs.linuxPackages_latest;

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

    system.build = {
      uboot = pkgs.uboot-mt7986a_bpir3_emmc.override {
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
          ENV_UBI_VOLUME_REDUND = freeform "ubootenv2";
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
