{ config, lib, ... }:
with lib;
{
  options.hardware.clearfog-a38x = {
    enable = mkEnableOption "clearfog-a38x";
  };
  config = mkIf config.hardware.clearfog-a38x.enable {
    hardware.deviceTree = {
      enable = true;
      filter = "armada-388-clearfog-*.dtb";
    };
  };
}
