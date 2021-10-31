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
    fonts.fonts = with pkgs; [
      dejavu_fonts
      hack-font
      inconsolata
      liberation_ttf
      noto-fonts
      noto-fonts-emoji
      source-code-pro
    ];
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraPackages = with pkgs; [
        bemenu
        brightnessctl
        clipman
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
        (pkgs.writeShellScriptBin "swaystatus" ''
          while true; do
            printf "%d%% | %s" "$(cat /sys/class/power_supply/BAT0/capacity)" "$(date +'%F %T')"
            sleep 1
          done
        '')
      ];
    };

    environment.etc."sway/config".source = ./config;
    environment.etc."gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-cursor-theme-name=Adwaita
      gtk-key-theme-name=Emacs
    '';

    environment.variables = {
      XCURSOR_THEME = "Adwaita";
      XCURSOR_PATH = mkForce [
        "${pkgs.gnome.adwaita-icon-theme}/share/icons"
      ];
    };

    custom.pipewire.enable = true;

    xdg.portal.enable = mkForce true;
    xdg.portal.extraPortals = with pkgs; [ xdg-desktop-portal-wlr ];
  };

}
