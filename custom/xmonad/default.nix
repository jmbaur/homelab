{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.xmonad;

  pa-switch = import ../../programs/pa-switch { };
in
{
  options = {
    custom.xmonad = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable custom xmonad setup.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "google-chrome"
      "slack"
      "spotify"
      "spotify-unwrapped"
      "zoom"
    ];

    environment.systemPackages = with pkgs; [
      brightnessctl
      chromium
      dunst
      element-desktop
      firefox
      gimp
      google-chrome
      imv
      kitty
      libreoffice
      pa-switch
      # pavucontrol
      # pinentry-gnome
      scrot
      signal-desktop
      slack
      spotify
      thunderbird
      wireshark
      xclip
      xsel
      zathura
      zoom-us
    ] ++ [

    ];

    fonts.fonts = with pkgs; [
      dejavu_fonts
      inconsolata
      liberation_ttf
      liberation_ttf
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      source-code-pro
    ];

    services = {
      xserver = {
        enable = true;
        layout = "us";
        xkbOptions = "ctrl:nocaps";
        deviceSection = ''
          Option "TearFree" "true"
        '';
        displayManager = {
          defaultSession = "none+xmonad";
          autoLogin.enable = true;
          autoLogin.user = "jared";
        };
        windowManager.xmonad = {
          enable = true;
          config = builtins.readFile ./xmonad.hs;
          enableContribAndExtras = true;
        };
      };
    };

  };

}
