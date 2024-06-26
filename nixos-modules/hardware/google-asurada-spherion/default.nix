{ config, lib, ... }:
with lib;
{
  options.hardware.asurada-spherion = {
    enable = mkEnableOption "google asurada-spherion board";
  };
  config = mkIf config.hardware.asurada-spherion.enable {
    hardware.chromebook.enable = true;
    hardware.enableRedistributableFirmware = true;
    hardware.deviceTree = {
      enable = true;
      filter = "mt8192-asurada-spherion*.dtb";
    };
  };
}
