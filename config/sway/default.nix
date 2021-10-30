{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.custom.sway;
in
{

  options = {
    custom.sway = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraPackages = with pkgs; [
        brightnessctl
        clipman
        dmenu
        file
        foot
        grim
        kanshi
        mako
        pulseaudio
        rofi
        slurp
        swayidle
        swaylock
        wf-recorder
        wl-clipboard
        xwayland
      ];
    };

    environment.variables.XCURSOR_PATH = mkForce [
      "${pkgs.gnome.adwaita-icon-theme}/share/icons"
    ];
    environment.variables.MOZ_ENABLE_WAYLAND = mkForce "1";
    xdg.portal.enable = mkForce true;
    xdg.portal.extraPortals = with pkgs; [ xdg-desktop-portal-wlr ];
  };


}
