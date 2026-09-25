{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware.armada-388-clearfog;

  onboardLinks = {
    "10-wan" = "end1";
    "10-lan" = "end2";
    "10-sfpplus" = "end3";
  };
in
{
  options.hardware.armada-388-clearfog = {
    enable = lib.mkEnableOption "armada-388-clearfog devices";

    falconPayload = lib.mkOption {
      type = lib.types.path;
      description = ''
        FIT image holding a kernel, a ramdisk and an fdt that u-boot SPL boots
        directly in falcon mode. There is no u-boot proper to fall back to.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.hostPlatform = {
      config = "armv7l-unknown-linux-gnueabihf";
      gcc = {
        arch = "armv7-a";
        fpu = "vfpv3-d16";
      };
    };

    boot.kernelParams = [ "console=ttyS0,115200" ];

    boot.kernelPackages = pkgs.linuxPackagesFor (
      pkgs.buildLinux {
        inherit (pkgs.linux_7_2) version src;
        autoModules = true;
        preferBuiltin = true;
        buildDTBs = true;
        target = "zImage";
        defconfig = "mvebu_v7_defconfig";
      }
    );

    boot.kernelPatches = [
      {
        name = "efi-support";
        patch = null;
        structuredExtraConfig = {
          EFI = lib.kernel.yes;
          EFI_STUB = lib.kernel.yes;
        };
      }

      # mvebu_v7_defconfig does not enable kexec, maybe because of this:
      # https://github.com/gregkh/linux/blob/7b923c78b50d2ec52690c4353e5aad8302e80599/arch/arm/mach-mvebu/pmsu.c#L507
      {
        name = "kexec-support";
        # Manual revert of https://patchwork.kernel.org/project/linux-arm-kernel/patch/1427820378-13415-1-git-send-email-gregory.clement@free-electrons.com/
        patch = ./cpuidle.patch;
        structuredExtraConfig = {
          KEXEC = lib.kernel.yes;
        };
      }
    ];

    hardware.deviceTree = {
      enable = true;
      filter = "armada-388-clearfog*.dtb";
      overlays = [
        {
          name = "mtd-partitions";
          dtsFile = ./clearfog-mtd-partitions.dtso;
        }
      ];
    };

    # end2 is the DSA master, end3 the 2.5Gbps link.
    systemd.network.links = lib.mapAttrs (link: kernelName: {
      matchConfig.OriginalName = kernelName;
      linkConfig.Name = lib.removePrefix "10-" link;
    }) onboardLinks;

    # Ensure the DSA master interface is bound to being up by it's slave
    # interfaces.
    systemd.network.networks."10-lan-master" = {
      name = "lan";
      linkConfig.RequiredForOnline = false;
      networkConfig.BindCarrier = map (i: "lan${toString i}") (lib.genList (i: i + 1) 6);
    };

    # solidrun clearfog uses BTN_0
    systemd.services.reset-button = {
      description = "Restart the system when the reset button is pressed";
      unitConfig.ConditionPathExists = [ "/dev/input/by-path/platform-gpio-keys-event" ];
      serviceConfig.ExecStart = toString [
        (lib.getExe' pkgs.evsieve "evsieve")
        "--input /dev/input/by-path/platform-gpio-keys-event"
        "--hook btn:0 exec-shell=\"systemctl reboot\""
      ];
      wantedBy = [ "multi-user.target" ];
    };

    environment.systemPackages = [
      pkgs.mtdutils
      (pkgs.writeShellScriptBin "update-firmware" ''
        set -eu

        ${lib.getExe' pkgs.mtdutils "flashcp"} \
          --verbose \
          ${config.system.build.firmware}/u-boot-spl.kwb \
          mtd:spl
        ${lib.getExe' pkgs.mtdutils "flashcp"} \
          --verbose \
          ${cfg.falconPayload} \
          mtd:tinyboot
      '')
    ];

    # name     start   size
    # ------------------------
    # spl      0KiB    1024KiB
    # tinyboot 1024KiB 3072KiB
    system.build.firmware = pkgs.makeUBoot {
      boardName = "clearfog_spi";
      artifacts = [ "u-boot-spl.kwb" ];
      meta.platforms = [ "armv7l-linux" ];

      patches = [
        ./0001-spl-fit-support-a-ramdisk-in-the-falcon-mode-payload.patch
        ./0002-arm-mvebu-clearfog-only-ever-boot-the-falcon-payload.patch
      ];

      # Same as u-boot-with-spl.kwb but without u-boot proper as the main
      # payload, SPL (as the binary header) being all the BootROM runs.
      postBuild = ''
        tools/mkimage -n arch/arm/mach-mvebu/kwbimage.cfg -T kwbimage -s u-boot-spl.kwb
      '';

      kconfig = with lib.kernel; {
        BOOTSTD_DEFAULTS = yes;
        BOOTSTD_FULL = yes;
        DISTRO_DEFAULTS = unset;
        FIT = yes;
        FIT_BEST_MATCH = yes; # TODO(jared): seems to not work
        SPL_FIT = yes;
        SYS_BOOTM_LEN = freeform "0x${lib.toHexString (50 * 1024 * 1024)}"; # 50MiB

        # Nothing reads the environment now that tinyboot, not u-boot proper,
        # is what boots the system.
        ENV_IS_IN_SPI_FLASH = unset;
        ENV_IS_NOWHERE = yes;

        # Falcon mode. The fdt is packaged in the payload rather than exported
        # separately, which is what lets the ramdisk come along with it.
        SPL_LOAD_FIT = yes;
        SPL_OS_BOOT = yes;
        SPL_OS_BOOT_ARGS = unset;
        SPL_OS_BOOT_SECURE = yes; # no fallback to u-boot proper
        SPL_OS_BOOT_RAMDISK = yes;
        SYS_SPI_KERNEL_OFFS = freeform "0x100000";
      };
    };

    # The mvneta interfaces have no address in hardware, and u-boot proper no
    # longer runs to hand one over, so generate each one once and keep it. The
    # addresses reach the interfaces as .link drop-ins rather than "ip link
    # set" so that any later udev event re-applies them too.
    systemd.services.stable-mac-address = {
      description = "Persistent MAC addresses for the on-board interfaces";
      wantedBy = [ "sysinit.target" ];
      # Nothing else pulls network-pre.target into the transaction, and it
      # refuses manual starts, so want it here as well as order against it.
      wants = [ "network-pre.target" ];
      before = [
        "network-pre.target"
        "shutdown.target"
      ];
      after = [
        "local-fs.target"
        "systemd-udev-trigger.service"
      ];
      conflicts = [ "shutdown.target" ];
      # systemd-networkd starts before basic.target, so this needs to as well
      unitConfig.DefaultDependencies = false;
      # Re-triggering udev would mean changing addresses out from under a
      # running network, and the stored ones do not change anyway.
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "stable-mac-address";
      };
      path = [
        pkgs.homelab-utils.macgen
        config.systemd.package # udevadm
      ];
      script = ''
        for link in ${toString (lib.attrNames onboardLinks)}; do
          address="$STATE_DIRECTORY/$link"
          if ! [[ -s "$address" ]]; then
            macgen >"$address"
          fi

          dropin="/run/systemd/network/$link.link.d"
          mkdir -p "$dropin"
          printf '[Link]\nMACAddress=%s\n' "$(cat "$address")" >"$dropin/50-mac-address.conf"
        done

        # Force udev to reapply link files
        udevadm control --reload
        udevadm trigger --subsystem-match=net --action=add --settle
      '';
    };

    # Recovery keeps u-boot proper, which the BootROM loads over UART.
    # usage: kwboot -b u-boot-with-spl.kwb /dev/ttyUSB0 && tio /dev/ttyUSB0
    system.build.uartFirmware = config.system.build.firmware.overrideAttrs (old: {
      artifacts = [ "u-boot-with-spl.kwb" ];
      postBuild = "";
      kconfig =
        with lib.kernel;
        old.kconfig
        // {
          MVEBU_SPL_BOOT_DEVICE_MMC = unset;
          MVEBU_SPL_BOOT_DEVICE_UART = yes;
          SPL_MMC = unset;
        };
    });

  };
}
