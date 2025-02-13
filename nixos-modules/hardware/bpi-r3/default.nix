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
        name = "mt7986a-wifi";
        patch = pkgs.fetchpatch {
          url = "https://raw.githubusercontent.com/openwrt/openwrt/06b37a5856ac7d0a2ddc2c0745ac1da3a01688d6/target/linux/mediatek/patches-6.6/195-dts-mt7986a-bpi-r3-leds-port-names-and-wifi-eeprom.patch";
          excludes = [ "arch/arm64/boot/dts/mediatek/mt7986a-bananapi-bpi-r3-nor.dtso" ]; # doesn't apply cleanly
          hash = "sha256-saqnN7A8nUYPLl7JtC6BEljmb+rmuUcgDIXTb3s55UE=";
        };
      }

      rec {
        name = pkgs.patchNameFromSubject "PCI: mediatek-gen3: handle PERST after reset";
        patch = pkgs.fetchpatch {
          inherit name;
          url = "https://lore.kernel.org/lkml/20230402131119.98805-1-linux@fw-web.de/raw";
          hash = "sha256-qyxc9DSfyO7kB52JR4rWY36ugzvEvTHCXPwhyrcV5fc=";
        };
      }

      rec {
        name = pkgs.patchNameFromSubject "arm64: dts: mediatek: mt7986: fix the switch reset line on BPI-R3";
        patch = pkgs.fetchpatch {
          inherit name;
          url = "https://lore.kernel.org/linux-arm-kernel/20240627075856.2314804-2-leith@bade.nz/raw";
          hash = "sha256-3kAnvJO/R7nTaahAimMQascL9mY9K375EKsbpDRVE3E=";
        };
      }

      rec {
        name = pkgs.patchNameFromSubject "arm64: dts: mediatek: mt7986: add gpio-hog for boot mode switch on BPI-R3";
        patch = pkgs.fetchpatch {
          inherit name;
          url = "https://lore.kernel.org/linux-arm-kernel/20240627075856.2314804-3-leith@bade.nz/raw";
          hash = "sha256-7FQLAWYtilj+MH34UAO80mztO9igYRJy5oPGc1ts5MQ=";
        };
      }

      rec {
        name = pkgs.patchNameFromSubject "arm64: dts: mediatek: mt7986: add missing pin groups to BPI-R3";
        patch = pkgs.fetchpatch {
          inherit name;
          url = "https://lore.kernel.org/linux-arm-kernel/20240627075856.2314804-4-leith@bade.nz/raw";
          hash = "sha256-YibxuXNlvGrLlbfqev2aiOdprzJcXwBRpq9yOik/gjc=";
        };
      }

      rec {
        name = pkgs.patchNameFromSubject "arm64: dts: mediatek: mt7986: add missing UART1 CTS/RTS pins in BPI-R3";
        patch = pkgs.fetchpatch {
          inherit name;
          url = "https://lore.kernel.org/linux-arm-kernel/20240627075856.2314804-5-leith@bade.nz/raw";
          hash = "sha256-Na7r1DxEkwJg0biDlzfjK8YxZu9Bi8i0MxygORdr3Wg=";
        };
      }

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
    ];

    hardware.firmware = [
      pkgs.wireless-regdb
      pkgs.mt7915-firmware
    ];

    boot.kernelParams = [ "console=ttyS0,115200" ];

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
