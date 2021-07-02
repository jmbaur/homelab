{ config, pkgs, ... }:

{
  home-manager.users.jared.programs.alacritty = {
    enable = true;
    settings = {
      env.TERM = "xterm-256color";
      font = {
        normal.family = "Hack";
        bold.family = "Hack";
        italic.family = "Hack";
        bold-italic.family = "Hack";
        size = 14.0;
      };
      colors.primary.background = "#000000";
      # mouse.hide_when_typing = true; # Not needed when unclutter is active.
    };
  };
}
