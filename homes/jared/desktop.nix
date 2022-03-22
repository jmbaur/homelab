{ config, lib, pkgs, ... }:
let
  cfg = config.custom.desktop;
in
{
  options.custom.desktop.enable = lib.mkEnableOption "Enable desktop configs";
  config = lib.mkIf cfg.enable {
    programs.i3status = {
      enable = true;
      enableDefault = false;
      general = {
        colors = true;
        interval = 5;
      };
      modules = {
        ipv6 = {
          position = 1;
        };
        "ethernet _first_" = {
          position = 2;
          settings = {
            format_down = "E: down";
            format_up = "E: %ip (%speed)";
          };
        };
        "disk /" = {
          position = 3;
          settings.format = "%avail";
        };
        load = {
          position = 4;
          settings.format = "%1min";
        };
        memory = {
          position = 5;
          settings = {
            format = "%used | %available";
            format_degraded = "MEMORY < %available";
            threshold_degraded = "1G";
          };
        };
        "tztime local" = {
          position = 6;
          settings.format = "%Y-%m-%d %H:%M:%S";
        };
      };
    };
  };
}
