{ config, lib, pkgs, ... }:
let
  cfg = config.custom.desktop;
in
{
  options.custom.desktop.enable = lib.mkEnableOption "Enable desktop configs";
  config = lib.mkIf cfg.enable {
    hardware.i2c.enable = true;
  };
}
