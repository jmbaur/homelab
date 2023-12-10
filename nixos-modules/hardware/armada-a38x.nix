{ config, lib, pkgs, ... }: {
  options.hardware.armada-a38x = {
    enable = lib.mkEnableOption "armada-38x devices";
  };

  config = lib.mkIf config.hardware.armada-a38x.enable {
    nixpkgs.hostPlatform = lib.recursiveUpdate lib.systems.platforms.armv7l-hf-multiplatform
      (lib.systems.examples.armv7l-hf-multiplatform // {
        linux-kernel = {
          name = "armada-38x";
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
      filter = "armada-38*.dtb";
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
        ${config.programs.flashrom.package}/bin/flashrom \
        --programmer linux_mtd:dev=0 \
        --write ${config.system.build.firmware}/firmware.bin
      '');

    system.build.firmware = pkgs.ubootClearfogSpi;

    # for fw_printenv and fw_setenv
    environment.etc."fw_env.config".text =
      let
        mtdpartsValue = lib.elemAt
          (lib.filter
            (lib.hasPrefix "CONFIG_MTDPARTS_DEFAULT")
            (lib.splitString "\n" config.system.build.firmware.extraConfig)) 0;
      in
      ''
        # values obtained from ${mtdpartsValue}
        # MTD device name       Device offset   Env. size       Flash sector size       Number of sectors
        /dev/mtd2               0x0000          0x40000         0x10000
      '';

  };
}
