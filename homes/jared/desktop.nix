{ config, lib, pkgs, ... }:
let
  cfg = config.custom.desktop;
in
{
  options.custom.desktop.enable = lib.mkEnableOption "Enable desktop configs";
  config = lib.mkIf cfg.enable {
    programs.i3status = {
      enable = true;
    };
  };
}
