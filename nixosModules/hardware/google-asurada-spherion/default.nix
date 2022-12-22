{ config, lib, pkgs, ... }:
with lib;
{
  options.hardware.asurada-spherion = {
    enable = mkEnableOption "google asurada-spherion board";
  };
  config = mkIf config.hardware.asurada-spherion.enable {
    custom.laptop.enable = true;
    hardware.chromebook.enable = true;
    hardware.bluetooth.enable = mkDefault true;
    hardware.enableRedistributableFirmware = true;
    hardware.deviceTree = {
      enable = true;
      filter = "mt8192-asurada-spherion*.dtb";
    };

    boot.kernelPackages = pkgs.linuxKernel.packagesFor pkgs.linux_chromiumos_mediatek;
  };
}
