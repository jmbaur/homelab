{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.hardware.cn9130-cf-pro.enable = lib.mkEnableOption "cn9130-cf-pro hardware support";

  config = lib.mkIf config.hardware.cn9130-cf-pro.enable {
    nixpkgs.hostPlatform = "aarch64-linux";

    system.build.firmware = pkgs.cn9130-cf-pro-firmware;

    boot.kernelParams = [ "cma=256M" ];

    hardware.deviceTree.name = "marvell/cn9130-cf-pro.dtb";

    boot.initrd.availableKernelModules = [
      "phy-armada38x-comphy"
      "phy-mvebu-cp110-utmi"
      "sdhci"
      "uas"
    ];

    systemd.network.links = {
      "10-wan" = {
        matchConfig.OriginalName = "eth2";
        linkConfig.Name = "wan";
      };
      "10-lan" = {
        matchConfig.OriginalName = "eth1";
        linkConfig.Name = "lan";
      };
      # 10Gbps link
      "10-sfpplus" = {
        matchConfig.OriginalName = "eth0";
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

    # solidrun cn9130-cf-pro uses BTN_0
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

    # TODO(jared): Add mtd partitions so we can edit U-Boot environment from
    # Linux.
    environment.systemPackages = [
      pkgs.uboot-env-tools
      pkgs.mtdutils
      (pkgs.writeShellScriptBin "update-firmware" ''
        ${lib.getExe' pkgs.mtdutils "flashcp"} \
          --verbose \
          ${config.system.build.firmware}/flash-image.bin \
          /dev/mtd0
      '')
    ];
  };
}
