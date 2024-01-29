{ config, lib, pkgs, ... }: {
  options.hardware.armada-388-clearfog = {
    enable = lib.mkEnableOption "armada-388-clearfog devices";
  };

  config = lib.mkIf config.hardware.armada-388-clearfog.enable {
    nixpkgs.hostPlatform = lib.recursiveUpdate lib.systems.platforms.armv7l-hf-multiplatform
      (lib.systems.examples.armv7l-hf-multiplatform // {
        linux-kernel = {
          name = "armada-388-clearfog";
          baseConfig = "mvebu_v7_defconfig";
        };
      });

    boot.kernelParams = [ "console=ttyS0,115200" ];

    # get helpful kernel logs regarding device peripherals
    boot.consoleLogLevel = 6;

    hardware.deviceTree = {
      enable = true;
      filter = "armada-388-clearfog*.dtb";
      overlays = [{
        name = "mtd-partitions";
        dtsFile = ./clearfog-mtd-partitions.dtso;
      }];
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
    systemd.network.networks.lan-master = {
      name = "lan";
      linkConfig.RequiredForOnline = false;
      networkConfig = {
        LinkLocalAddressing = "no";
        BindCarrier = map (i: "lan${toString i}") [ 1 2 3 4 5 ];
      };
    };

    # https://github.com/torvalds/linux/blob/815fb87b753055df2d9e50f6cd80eb10235fe3e9/include/uapi/linux/input-event-codes.h#L344
    # solidrun clearfog uses BTN_0
    # BTN_0 == 0x100 == 256
    systemd.services.reset-button = {
      description = "Restart the system when the reset button is pressed";
      unitConfig.ConditionPathExists = [ "/dev/input/by-path/platform-gpio-keys-event" ];
      # make sure evsieve button identifiers are escaped
      serviceConfig.ExecStart = lib.replaceStrings [ "%" ] [ "%%" ]
        (toString [
          (lib.getExe' pkgs.evsieve "evsieve")
          "--input /dev/input/by-path/platform-gpio-keys-event"
          "--hook btn:%256 exec-shell=\"systemctl reboot\""
        ]);
      wantedBy = [ "multi-user.target" ];
    };

    environment.systemPackages = with pkgs; [
      ubootEnvTools
      mtdutils
      (pkgs.writeShellScriptBin "update-firmware" ''
        ${lib.getExe' pkgs.mtdutils "flashcp"} --verbose ${config.system.build.firmware}/u-boot-with-spl.kwb mtd:uboot
      '')
    ];

    # name           start     size
    # -----------------------------
    # uboot           0KiB  2048KiB
    # ubootenv     2048KiB   128KiB
    # ubootenvred  2176KiB   128KiB
    # empty        2304KiB  1792KiB
    system.build.firmware = pkgs.uboot-clearfog_spi.override {
      extraStructuredConfig = with pkgs.ubootLib; {
        BOOTCOUNT_ENV = yes;
        BOOTCOUNT_LIMIT = yes;
        BOOTSTD_DEFAULTS = yes;
        BOOTSTD_FULL = yes;
        DISTRO_DEFAULTS = unset;
        ENV_OFFSET = freeform "0x200000";
        ENV_OFFSET_REDUND = freeform "0x220000";
        ENV_SECT_SIZE = freeform "0x10000";
        ENV_SIZE = freeform "0x20000";
        ENV_SIZE_REDUND = freeform "0x20000";
        FIT = yes;
        FIT_BEST_MATCH = yes;
        SYS_BOOTM_LEN = freeform "0x${lib.toHexString (12 * 1024 * 1024)}"; # 12MiB
        SYS_REDUNDAND_ENVIRONMENT = yes;
      };
    };

    # The default load address is 0x800000, so let's leave up to 32MiB for
    # the fit-image.
    custom.image.uboot.kernelLoadAddress = "0x2800000";

    # for fw_printenv and fw_setenv
    environment.etc."fw_env.config".text = ''
      # MTD device name       Device offset   Env. size       Flash sector size       Number of sectors
      /dev/mtd2               0x0             0x20000         0x10000
    '';

    # If no variables for these mac addresses exist, we need to generate them
    # so the device has persistent mac addresses across reboots.
    systemd.services.stable-mac-address = {
      path = with pkgs; [ gnugrep ubootEnvTools macgen ];
      script = ''
        if ! fw_printenv | grep --silent ethaddr; then
          tmp=$(mktemp)
          echo "ethaddr $(macgen)" | tee -a $tmp
          echo "eth1addr $(macgen)" | tee -a $tmp
          echo "eth2addr $(macgen)" | tee -a $tmp
          echo "eth3addr $(macgen)" | tee -a $tmp
          fw_setenv --script $tmp
          echo "wrote new macaddrs to uboot environment"
          rm $tmp
        fi
      '';
    };
  };
}
