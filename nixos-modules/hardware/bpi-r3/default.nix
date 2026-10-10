{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.hardware.bpi-r3.enable = lib.mkEnableOption "bananapi r3";

  config = lib.mkIf config.hardware.bpi-r3.enable {
    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

    # 7.3 has fixes needed for stable WED on mt7986 (WO firmware loading, WDMA
    # TX hang).
    # TODO(jared): switch to linuxPackages_7_3 once it is available
    boot.kernelPackages = pkgs.linuxPackages_testing;

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
            name = baseNameOf dtsFile;
          })
          [
            ./wifi-calibration.dtso
            ./nand.dtso
            ./emmc.dtso
            ./disable-pcie.dtso
          ];
    };

    boot.kernelPatches = [
      {
        name = "mt7986-common-config";
        # The nixos kernel configurator is not capable of overriding what is in the defconfig...
        patch = ./defconfig.patch;
        # Misbehaving drivers (and their dependencies) that don't work well when built as modules.
        structuredExtraConfig = with lib.kernel; {
          BRIDGE = yes;
          HSR = yes;
          NET_DSA = yes;
          NET_DSA_MT7530 = yes;
          NET_DSA_TAG_MTK = yes;
          NET_MEDIATEK_SOC = yes;
          # Only knows about Chromebook/Genio SoCs, fails to probe on mt7986
          MTK_SOCINFO = no;
          # Nothing uses the mtdblock devices (UBI and flashcp use the MTD
          # character devices), and it warns about each NAND partition.
          MTD_BLOCK = no;
        };
      }
      {
        name = "pcie-mediatek-gen3-builtin";
        patch = null;
        structuredExtraConfig.PCIE_MEDIATEK_GEN3 = lib.kernel.yes; # TODO(jared): is this needed?
      }
      {
        # TODO(jared): drop once upstreamed
        name = "mt7915-wed-wcid-mt798x";
        patch = ./mt7915-wed-wcid-mt798x.patch;
      }
      {
        name = "switch-reset-line-fix";
        patch = ./0001-arm64-dts-mediatek-mt7986-fix-the-switch-reset-line-.patch;
      }
      {
        name = "boot-mode-gpio-hog";
        patch = ./0002-arm64-dts-mediatek-mt7986-add-gpio-hog-for-boot-mode.patch;
      }
      {
        name = "add-missing-pin-groups";
        patch = ./0003-arm64-dts-mediatek-mt7986-add-missing-pin-groups-to-.patch;
      }
      {
        name = "uart1-fixes";
        patch = ./0004-arm64-dts-mediatek-mt7986-add-missing-UART1-CTS-RTS-.patch;
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

    boot.kernelParams = [
      # TODO(jared): Sometimes the mt7530 MDIO bus will timeout. This seems to
      # prevent that from happening.
      "clk_ignore_unused"
    ];

    # The kernel tries to iterate the MTD partitions in the initrd, but we need
    # to provide the kernel modules to allow it to do so.
    boot.initrd.availableKernelModules = [
      "spinand"
      "ubi"
    ];

    # TODO(jared): WED makes wifi clients flaky, even on 7.3-rc6 with the WCID
    # fix. Wired flows are still offloaded via nftables-flow-offload below,
    # wifi devices don't advertise hw-tc-offload without WED.
    boot.extraModprobeConfig = ''
      options mt7915e wed_enable=N
      options ubi mtd=ubi
    '';

    environment.etc."fw_env.config".text = ''
      /dev/ubi0:ubootenv    0x0 0x1f000 0x1f000
      /dev/ubi0:ubootenvred 0x0 0x1f000 0x1f000
    '';

    # Offload established forwarded flows to the mt7986 PPE, and with WED
    # enabled, directly to/from the wifi radios. This lives outside of the main
    # ruleset since the flowtable devices are only known at runtime, and a
    # failure here should not take the firewall down with it.
    #
    # Only devices that currently support hw-tc-offload are added (similar to
    # OpenWrt's fw4). The kernel refuses to register a device matching an
    # offload flowtable's device list if it can't offload, so listing devices
    # that can't (e.g. wifi when WED failed to attach) would break them.
    systemd.services.nftables-flow-offload = lib.mkIf config.router.enable {
      description = "nftables flow offloading";
      wantedBy = [ "multi-user.target" ];
      # wifi devices only advertise hw-tc-offload once WED is attached, which
      # happens when the driver probes.
      wants = [ "modprobe@mt7915e.service" ];
      after = [
        "nftables.service"
        "network.target"
        "modprobe@mt7915e.service"
      ];
      path = [
        pkgs.ethtool
        pkgs.jq
        pkgs.nftables
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${lib.getExe pkgs.nftables} destroy table inet flow-offload";
      };
      # The forward chain runs before the nixos-fw forward chain. Flows are only
      # added once conntrack has confirmed them, so this only offloads
      # connections the nixos-fw forward chain already accepted.
      script = ''
        devices=()
        for path in /sys/class/net/*; do
          device=''${path##*/}
          # Only physical devices, the bridge is resolved by the kernel
          [[ -e $path/device ]] || continue
          # Skip DSA conduits, their user ports are added instead
          [[ -e $path/dsa ]] && continue
          if ethtool --json --show-features "$device" | jq --exit-status '.[0]."hw-tc-offload".active' >/dev/null; then
            devices+=("\"$device\"")
          fi
        done

        if [[ ''${#devices[@]} -eq 0 ]]; then
          echo "No devices support hw-tc-offload, not offloading flows"
          exit 0
        fi

        echo "Offloading flows on: ''${devices[*]}"

        nft --file - <<EOF
        destroy table inet flow-offload

        table inet flow-offload {
          flowtable ft {
            hook ingress priority filter
            devices = { $(IFS=,; echo "''${devices[*]}") }
            flags offload
          }

          chain forward {
            type filter hook forward priority filter - 1; policy accept;
            meta l4proto { tcp, udp } flow add @ft
          }
        }
        EOF
      '';
    };

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

    # The 2.4GHz radio defaults to 29dBm, which overheats its front-end chip
    # (MT7975N) to the point of firmware thermal throttling. 20dBm is plenty
    # for indoor coverage. The mt7915 driver ignores TX power set on an
    # interface, so it must be set on the phy.
    systemd.services.hostapd.serviceConfig.ExecStartPre = lib.mkIf config.services.hostapd.enable [
      (pkgs.writeShellScript "bpi-r3-2ghz-txpower" (
        lib.concatMapStrings (iface: ''
          ${lib.getExe pkgs.iw} phy "$(</sys/class/net/${iface}/phy80211/name)" set txpower fixed 2000
        '') (lib.attrNames (lib.filterAttrs (_: radio: radio.band == "2g") config.services.hostapd.radios))
      ))
    ];

    system.build = {
      uboot = pkgs.makeUBoot {
        boardName = "mt7986a_bpir3_emmc";
        artifacts = [
          ".config"
          "u-boot.bin"
        ];
        meta.platforms = [ "aarch64-linux" ];

        patches = [ ./mt7986-persistent-mac-from-cpu-uid.patch ];

        kconfig = with lib.kernel; {
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
          # The mt7986 u-boot device tree has no psci node, so the PSCI
          # firmware driver never probes and the EFI runtime reset spins
          # forever instead of resetting. Don't advertise it so linux resets
          # via PSCI directly.
          EFI_HAVE_RUNTIME_RESET = no;
          EFI_LOADER = yes;
          ENV_IS_IN_MMC = unset;
          ENV_IS_IN_UBI = yes;
          ENV_OFFSET = unset;
          ENV_SIZE = freeform "0x1f000";
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
        inherit (config.system.build) uboot;
      };

      # mtk_uartboot \
      #   --aarch64 \
      #   --brom-load-baudrate 115200 --bl2-load-baudrate 115200 \
      #   -s /dev/ttyUSB0 \
      #   -p ./path/to/bl2.bin \
      #   -f ./path/to/fip.bin
      uartBootFirmware = config.system.build.firmware.override { uartBoot = true; };
    };
  };
}
