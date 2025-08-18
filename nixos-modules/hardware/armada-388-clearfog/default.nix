{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.hardware.armada-388-clearfog.enable = lib.mkEnableOption "armada-388-clearfog devices";

  config = lib.mkIf config.hardware.armada-388-clearfog.enable {
    nixpkgs.hostPlatform = {
      config = "armv7l-unknown-linux-gnueabihf";
      gcc = {
        arch = "armv7-a";
        fpu = "vfpv3-d16";
      };
      linux-kernel = {
        DTB = true;
        autoModules = true;
        preferBuiltin = true;
        target = "zImage";
        name = "armada-388-clearfog";
        baseConfig = "mvebu_v7_defconfig";
      };
    };

    boot.kernelParams = [ "console=ttyS0,115200" ];

    boot.kernelPatches = [
      {
        name = "efi-support";
        patch = null;
        structuredExtraConfig = {
          EFI = lib.kernel.yes;
          EFI_STUB = lib.kernel.yes;
        };
      }

      # mvebu_v7_defconfig does not enable kexec
      {
        name = "kexec-support";
        patch = null;
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

    systemd.network.links = {
      "10-wan" = {
        matchConfig.OriginalName = "end1";
        linkConfig.Name = "wan";
      };
      # DSA master
      "10-lan" = {
        matchConfig.OriginalName = "end2";
        linkConfig.Name = "lan";
      };
      # 2.5Gbps link
      "10-sfpplus" = {
        matchConfig.OriginalName = "end3";
        linkConfig.Name = "sfpplus";
      };
    };

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
      pkgs.uboot-env-tools
      pkgs.mtdutils
      (pkgs.writeShellScriptBin "update-firmware" ''
        ${lib.getExe' pkgs.mtdutils "flashcp"} \
          --verbose \
          ${config.system.build.firmware}/u-boot-with-spl.kwb \
          mtd:uboot
      '')
    ];

    # name           start     size
    # -----------------------------
    # uboot           0KiB  2048KiB
    # ubootenv     2048KiB   128KiB
    # ubootenvred  2176KiB   128KiB
    # empty        2304KiB  1792KiB
    system.build.firmware = pkgs.uboot-clearfog_spi.override {
      extraStructuredConfig = with lib.kernel; {
        BOOTCOUNT_ENV = yes;
        BOOTCOUNT_LIMIT = yes;
        BOOTSTD_DEFAULTS = yes;
        BOOTSTD_FULL = yes;
        DISTRO_DEFAULTS = unset;
        ENV_OFFSET = freeform "0x200000";
        ENV_OFFSET_REDUND = freeform "0x220000";
        ENV_SECT_SIZE = freeform "0x10000";
        ENV_SIZE = freeform "0x20000";
        FIT = yes;
        FIT_BEST_MATCH = yes; # TODO(jared): seems to not work
        SYS_BOOTM_LEN = freeform "0x${lib.toHexString (50 * 1024 * 1024)}"; # 50MiB
        SYS_REDUNDAND_ENVIRONMENT = yes;
      };
    };

    # usage: kwboot -b u-boot-with-spl.kwb /dev/ttyUSB0 && tio /dev/ttyUSB0
    system.build.uartFirmware = config.system.build.firmware.override {
      structuredExtraConfig = with lib.kernel; {
        ENV_IS_IN_MMC = unset;
        ENV_IS_NOWHERE = yes;
        MVEBU_SPL_BOOT_DEVICE_MMC = unset;
        MVEBU_SPL_BOOT_DEVICE_UART = yes;
        SPL_MMC = unset;
      };
    };

    environment.etc."fw_env.config".text = ''
      /dev/mtd2 0x0 0x20000 0x10000
      /dev/mtd1 0x0 0x20000 0x10000
    '';

    # If no variables for these mac addresses exist, we need to generate them
    # so the device has persistent mac addresses across reboots.
    systemd.services.stable-mac-address = {
      unitConfig.ConditionFirstBoot = true;
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.macgen
        pkgs.uboot-env-tools
      ];
      script = ''
        if ! fw_printenv | grep --silent 'eth[1-3]addr'; then
          for index in 1 2 3; do
            echo "eth''${index}addr $(macgen)"
          done | fw_setenv --script
          echo "Wrote new MAC addresses to uboot environment, reboot to take effect."
        fi
      '';
    };
  };
}
