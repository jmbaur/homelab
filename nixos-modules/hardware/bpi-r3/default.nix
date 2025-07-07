{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.hardware.bpi-r3.enable = lib.mkEnableOption "bananapi r3";

  config = lib.mkIf config.hardware.bpi-r3.enable {
    boot.kernelPackages = pkgs.linuxPackages_6_15;

    hardware.firmware = [
      pkgs.wireless-regdb
      (pkgs.extractLinuxFirmwareDirectory "mediatek")
    ];

    hardware.deviceTree = {
      enable = true;
      name = "mediatek/mt7986a-bananapi-bpi-r3.dtb";
      overlays =
        map
          (dtsFile: {
            inherit dtsFile;
            name = builtins.baseNameOf dtsFile;
          })
          [
            ./mt7986a-wifi.dtso
            ./nand.dtso
            ./emmc.dtso
          ];
    };

    environment.systemPackages = [
      pkgs.mtdutils
      pkgs.uboot-env-tools
      (pkgs.writeShellScriptBin "update-firmware" ''
        ${lib.getExe' pkgs.mtdutils "flashcp"} --verbose ${config.system.build.firmware}/bl2.img mtd:bl2
        ${lib.getExe' pkgs.mtdutils "flashcp"} --verbose ${config.system.build.firmware}/fip.bin mtd:fip
      '')
    ];

    # TODO(jared): There is an issue where uboot advertises the ability to
    # perform a reset via the EFI runtime services, however the linux kernel
    # hangs indefinitely when it attempts to use it, so in the meantime, don't
    # use it!
    boot.kernelParams = [ "efi=noruntime" ];

    boot.kernelModules = [ "ubi" ];

    boot.extraModprobeConfig = ''
      options ubi mtd=ubi
      options mt7915e wed_enable=Y
    '';

    environment.etc."fw_env.config".text = ''
      /dev/ubi0:ubootenv    0x0 0x1f000 0x1f000
      /dev/ubi0:ubootenvred 0x0 0x1f000 0x1f000
    '';

    # bpi-r3 uses KEY_RESTART
    systemd.services.reset-button = {
      description = "Restart the system when the reset button is pressed";
      unitConfig.ConditionPathExists = [ "/dev/input/by-path/platform-gpio-keys-event" ];
      serviceConfig.ExecStart = toString [
        (lib.getExe' pkgs.evsieve "evsieve")
        "--input /dev/input/by-path/platform-gpio-keys-event"
        "--hook key:restart exec-shell=\"systemctl reboot\""
      ];
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
              WDT = yes;
              WDT_MTK = yes;
            };
          };

      firmware = pkgs.callPackage ./firmware.nix {
        uboot-mt7986a_bpir3_emmc = config.system.build.uboot;
      };
    };
  };
}
