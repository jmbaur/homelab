{ config, lib, pkgs, ... }:
let
  cfg = config.hardware.cn913x;
in
{
  options.hardware.cn913x.enable = lib.mkEnableOption "cn913x hardware";
  config = lib.mkIf cfg.enable {
    boot.initrd.systemd.enable = true;
    boot.kernelParams = [ "console=ttyS0,115200" "cma=256M" ];
    boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_cn913x;
    hardware.deviceTree = {
      enable = true;
      filter = "cn913*.dtb";
    };
  };
}

