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

    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;
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
      unitConfig.ConditionPathExists = [ "/dev/input/event0" ];
      # make sure evsieve button identifiers are escaped
      serviceConfig.ExecStart = lib.replaceStrings [ "%" ] [ "%%" ]
        (toString [
          (lib.getExe' pkgs.evsieve "evsieve")
          "--input /dev/input/event0"
          "--hook btn:%256 exec-shell=\"systemctl reboot\""
        ]);
      wantedBy = [ "multi-user.target" ];
    };

    programs.flashrom.enable = lib.mkDefault true;

    environment.systemPackages = [
      pkgs.ubootEnvTools
    ] ++ lib.optional config.programs.flashrom.enable
      (pkgs.writeShellScriptBin "update-firmware" ''
        firmware=$(mktemp)

        dd bs=1 count=$((0x200000)) if=/dev/zero of=$firmware
        dd conv=notrunc if=${config.system.build.firmware}/u-boot-with-spl.kwb of=$firmware

        ${config.programs.flashrom.package}/bin/flashrom \
          --programmer linux_mtd:dev=0 \
          --write $firmware
      '');

    system.build.firmware = pkgs.uboot-clearfog_spi;
    custom.image.ubootLoadAddress = config.system.build.firmware.config.SYS_LOAD_ADDR.value;

    # for fw_printenv and fw_setenv
    environment.etc."fw_env.config".text = ''
      # MTD device name       Device offset   Env. size       Flash sector size       Number of sectors
      /dev/mtd2               0x0000          0x40000         0x10000
    '';
  };
}
