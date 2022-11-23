{ config, lib, pkgs, ... }:
with lib;
{
  options.hardware.cn913x = {
    enable = mkEnableOption "clearfog-cn913x";
  };
  config = mkIf config.hardware.cn913x.enable {
    boot.initrd.systemd.enable = true;
    boot.kernelParams = [ "cma=256M" ];
    boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_cn913x;
    hardware.deviceTree = {
      enable = true;
      filter = "cn913*.dtb";
    };
  };
}
