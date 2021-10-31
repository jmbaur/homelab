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

    services.xserver = {
      enable = true;
      layout = "us";
      xkbOptions = "ctrl:nocaps";
      # displayManager = {
      #   defaultSession = "none+awesome";
      #   autoLogin = { enable = true; user = "jared"; };
      # };
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
