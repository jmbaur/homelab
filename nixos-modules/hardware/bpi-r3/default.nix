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
      # TODO(jared): USB not working yet
      uboot = pkgs.uboot-mt7986a_bpir3_emmc.override {
        extraStructuredConfig = with pkgs.ubootLib; {
          MTD = yes;
          DM_MTD = yes;
          SPI = yes;
          DM_SPI = yes;
          MTD_SPI_NAND = yes;
          CMD_MTD = yes;
          MTK_SPIM = yes;
          USB = yes;
          DM_USB = yes;
          CMD_USB = yes;
          USB_HOST = yes;
          USB_XHCI_HCD = yes;
          USB_XHCI_MTK = yes;
          USB_STORAGE = yes;
          SUPPORT_EMMC_BOOT = yes;
          AUTOBOOT = yes;
          USE_BOOTCOMMAND = yes;
          BOOTSTD_DEFAULTS = yes;
          BOOTSTD_FULL = yes;
          FIT = yes;
          BOOTCOUNT_LIMIT = yes;
          BOOTCOUNT_ENV = yes;
        };
      };

      firmware = pkgs.callPackage ./firmware.nix {
        uboot-mt7986a_bpir3_emmc = config.system.build.uboot;
      };
    };
  };
}
