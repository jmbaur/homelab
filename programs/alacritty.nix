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
      # mouse.hide_when_typing = true; # Not needed when unclutter is active.
      colors = {
        primary.background = "0x0A0E14";
        primary.foreground = "0xB3B1AD";
        normal = {
          black = "0x01060E";
          red = "0xEA6C73";
          green = "0x91B362";
          yellow = "0xF9AF4F";
          blue = "0x53BDFA";
          magenta = "0xFAE994";
          cyan = "0x90E1C6";
          white = "0xC7C7C7";
        };
        bright = {
          black = "0x686868";
          red = "0xF07178";
          green = "0xC2D94C";
          yellow = "0xFFB454";
          blue = "0x59C2FF";
          magenta = "0xFFEE99";
          cyan = "0x95E6CB";
          white = "0xFFFFFF";
        };
      };

    };
  };
}
