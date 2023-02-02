{ config, lib, pkgs, ... }: {
  options.hardware.clearfog-a38x = {
    enable = lib.mkEnableOption "clearfog-a38x";
  };

  config = lib.mkIf config.hardware.clearfog-a38x.enable {
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;
    boot.kernelParams = [ "console=ttyS0,115200" ];

    programs.flashrom.enable = true;
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "update-bios" ''
        ${config.programs.flashrom.package}/bin/flashrom \
          --programmer linux_mtd:dev=0 \
          --write ${pkgs.ubootClearfogSpi}/spi.img
      '')
    ];

    hardware.deviceTree = {
      enable = true;
      filter = "armada-388-clearfog-*.dtb";
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
