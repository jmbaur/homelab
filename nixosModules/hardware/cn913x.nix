{ config, lib, pkgs, ... }:
with lib;
{
  options.hardware.clearfog-cn913x = {
    enable = mkEnableOption "clearfog-cn913x";
  };
  config = mkIf config.hardware.clearfog-cn913x.enable {
    boot.initrd.systemd.enable = true;
    boot.kernelParams = [ "console=ttyS0,115200" "cma=256M" ];
    boot.kernelPackages = pkgs.linuxKernel.packagesFor pkgs.linux_cn913x;

    hardware.deviceTree = {
      enable = true;
      filter = "cn913*.dtb";
    };

    systemd.network.links = {
      "10-wan" = {
        matchConfig.OriginalName = "eth2";
        linkConfig.Name = "wan";
      };
      # 10Gbps link
      "10-data" = {
        matchConfig.OriginalName = "eth0";
        linkConfig.Name = "data";
      };
    };
  };
}
