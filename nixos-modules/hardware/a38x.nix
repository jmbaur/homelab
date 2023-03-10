{ config, lib, pkgs, ... }: {
  options.hardware.armada-a38x = {
    enable = lib.mkEnableOption "armada-38x devices";
  };

  config = lib.mkIf config.hardware.armada-a38x.enable {
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;
    boot.kernelParams = [ "console=ttyS0,115200" ];
    boot.kernelPackages = pkgs.linuxKernel.packagesFor pkgs.linux_mvebu_v7;

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
      linkConfig.RequiredForOnline = "no";
      networkConfig = {
        LinkLocalAddressing = "no";
        BindCarrier = map (i: "lan${toString i}") [ 1 2 3 4 5 6 ];
      };
    };
  };
}