{ config, pkgs, ... }: {
  home-manager.users.jared.programs.kitty = {
    enable = true;
    font = {
      name = "Hack";
      size = 16;
    };
    settings = {
      term = "xterm-256color";
      mouse_hide_wait = 3;
      scrollback_lines = 10000;
      enable_audio_bell = false;
      update_check_interval = 0;
      copy_on_select = "yes";
      # Colors
      background = "#0e1419";
      foreground = "#e5e1cf";
      cursor = "#f19618";
      selection_background = "#243340";
      color0 = "#000000";
      color8 = "#323232";
      color1 = "#ff3333";
      color9 = "#ff6565";
      color2 = "#b8cc52";
      color10 = "#e9fe83";
      color3 = "#e6c446";
      color11 = "#fff778";
      color4 = "#36a3d9";
      color12 = "#68d4ff";
      color5 = "#f07078";
      color13 = "#ffa3aa";
      color6 = "#95e5cb";
      color14 = "#c7fffc";
      color7 = "#ffffff";
      color15 = "#ffffff";
      selection_foreground = "#0e1419";
    };
  };
}
