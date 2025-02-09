{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.hardware.cn9130-cf-pro.enable = lib.mkEnableOption "cn9130-cf-pro";

  config = lib.mkIf config.hardware.cn9130-cf-pro.enable {
    nixpkgs.hostPlatform = "aarch64-linux";

    system.build.firmware = pkgs.cn9130CfProSpiFirmware;

    boot.kernelParams = [
      "console=ttyS0,115200"
      "cma=256M"
    ];

    hardware.deviceTree.name = "marvell/cn9130-cf-pro.dtb";
    boot.kernelPackages = pkgs.linuxPackages_6_12; # board introduced in linux 6.11

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
  };
}
