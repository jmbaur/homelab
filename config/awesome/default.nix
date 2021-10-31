{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom.awesome;
in
{

  options = {
    custom.awesome = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      laptop = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {

    fonts.fonts = with pkgs; [
      dejavu_fonts
      hack-font
      inconsolata
      liberation_ttf
      noto-fonts
      noto-fonts-emoji
      source-code-pro
    ];

    environment.etc."xdg/awesome/rc.lua".source = ./rc.lua;
    environment.etc."xdg/awesome/themes/theme.lua".source = ./theme.lua;
    environment.etc."gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-cursor-theme-name = Adwaita
      gtk-key-theme-name = Emacs
      gtk-theme-name = Adwaita
    '';

    environment.variables.XCURSOR_THEME = "Adwaita";

    environment.systemPackages = with pkgs; [
      brightnessctl
      pulseaudio
      xclip
      xsel
    ];

    services.xserver = {
      enable = true;
      layout = "us";
      xkbOptions = "ctrl:nocaps";
      displayManager = {
        defaultSession = "none+awesome";
        autoLogin = { enable = true; user = "jared"; };
      };
      deviceSection = ''
        Option "TearFree" "true"
      '';
      windowManager.awesome.enable = true;
      libinput = mkIf cfg.laptop {
        enable = true;
        touchpad = {
          accelProfile = "flat";
          tapping = true;
          naturalScrolling = true;
        };
      };
    };
  };

}
