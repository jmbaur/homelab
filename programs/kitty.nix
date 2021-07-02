{ config, pkgs, ... }: {
  home-manager.users.jared.programs.kitty = {
    enable = true;
    font = {
      name = "Hack";
      size = 16;
    };
    settings = {
      term = "xterm-256color";
      scrollback_lines = 10000;
      enable_audio_bell = false;
      update_check_interval = 0;
      copy_on_select = "yes";
      background = "#000000";
      foreground = "#ffffff";
      cursor = "#ffffff";
      selection_background = "#b4d5ff";
      selection_foreground = "#000000";
      color0 = "#000000";
      color8 = "#545753";
      color1 = "#cc0000";
      color9 = "#ef2828";
      color2 = "#4e9a05";
      color10 = "#8ae234";
      color3 = "#c4a000";
      color11 = "#fce94e";
      color4 = "#3464a4";
      color12 = "#719ecf";
      color5 = "#74507a";
      color13 = "#ad7ea7";
      color6 = "#05989a";
      color14 = "#34e2e2";
      color7 = "#d3d7cf";
      color15 = "#ededec";
    };
  };
}
