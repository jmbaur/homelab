{ config, pkgs, ... }:

{
  home-manager.users.jared.programs.i3status-rust = {
    enable = true;
    bars = {
      top = {
        blocks = [
          {
            block = "networkmanager";
            primary_only = true;
          }
          {
            block = "disk_space";
            path = "/";
            alias = "/";
            info_type = "available";
            unit = "GB";
            interval = 60;
            warning = 20.0;
            alert = 10.0;
          }
          {
            block = "memory";
            display_type = "memory";
            format_mem = "{mem_used_percents}";
            format_swap = "{swap_used_percents}";
          }
          {
            block = "cpu";
            interval = 1;
          }
          { block = "sound"; }
          { block = "battery"; }
          {
            block = "time";
            interval = 1;
            format = "%F %T";
          }
        ];
        theme = "native";
      };
    };
  };
}
