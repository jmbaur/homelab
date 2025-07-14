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
            ./wifi-calibration.dtso
            ./nand.dtso
            ./emmc.dtso
            ./disable-gpio-keys.dtso
          ];
    };

    boot.kernelPatches = [
      {
        name = "pcie-perst-fix";
        patch = ./pcie-perst.patch;
        extraStructuredConfig.PCIE_MEDIATEK_GEN3 = lib.kernel.yes; # TODO(jared): is this needed?
      }
      {
        name = "switch-reset-line-fix";
        patch = pkgs.fetchpatch {
          url = "https://lore.kernel.org/linux-arm-kernel/20240627075856.2314804-2-leith@bade.nz/raw";
          hash = "sha256-3kAnvJO/R7nTaahAimMQascL9mY9K375EKsbpDRVE3E=";
        };
      }
      {
        name = "boot-mode-gpio-hog";
        patch = pkgs.fetchpatch {
          url = "https://lore.kernel.org/linux-arm-kernel/20240627075856.2314804-3-leith@bade.nz/raw";
          hash = "sha256-7FQLAWYtilj+MH34UAO80mztO9igYRJy5oPGc1ts5MQ=";
        };
      }
      {
        name = "add-missing-pin-groups";
        patch = pkgs.fetchpatch {
          url = "https://lore.kernel.org/linux-arm-kernel/20240627075856.2314804-4-leith@bade.nz/raw";
          hash = "sha256-YibxuXNlvGrLlbfqev2aiOdprzJcXwBRpq9yOik/gjc=";
        };
      }
      {
        name = "uart1-fixes";
        patch = pkgs.fetchpatch {
          url = "https://lore.kernel.org/linux-arm-kernel/20240627075856.2314804-5-leith@bade.nz/raw";
          hash = "sha256-Na7r1DxEkwJg0biDlzfjK8YxZu9Bi8i0MxygORdr3Wg=";
        };
      }
    ];

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

    # The kernel tries to iterate the MTD partitions in the initrd, but we need
    # to provide the kernel modules to allow it to do so.
    boot.initrd.availableKernelModules = [
      "spinand"
      "ubi"
    ];

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
          patches = (old.patches or [ ]) ++ [
            ./mt7986-persistent-mac-from-cpu-uid.patch
            (pkgs.fetchpatch {
              url = "https://github.com/u-boot/u-boot/commit/1bf212129768d65a47145209c65bf37b6082d718.patch";
              hash = "sha256-+xQ5Rb4feoVA3MBj9AnYlz3U14lmBLlvBx07ZpyTKOE=";
            })
          ];
        })).override
          {
            extraStructuredConfig = with lib.kernel; {
              AHCI = yes;
              AHCI_PCI = yes;
              AUTOBOOT = yes;
              BLK = yes;
              BOARD_LATE_INIT = yes;
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
              CMD_WDT = yes;
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
