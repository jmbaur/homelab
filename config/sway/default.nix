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
      extraSessionCommands = ''
        # SDL:
        export SDL_VIDEODRIVER=wayland
        # QT (needs qt5.qtwayland in systemPackages):
        export QT_QPA_PLATFORM=wayland-egl
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        # Fix for some Java AWT applications (e.g. Android Studio),
        # use this if they aren't displayed properly:
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
      extraPackages = with pkgs; [
        bemenu
        brightnessctl
        clipman
        grim
        kanshi
        mako
        pulseaudio
        slurp
        swayidle
        swaylock
        wf-recorder
        wl-clipboard
        xorg.xeyes
        xwayland
        (writeShellScriptBin "swaystatus" ''
          while true; do
            printf "%d%% | %s" "$(cat /sys/class/power_supply/BAT0/capacity)" "$(date +'%F %T')"
            sleep 1
          done
        '')
      ];
    };

    environment.etc = {
      "sway/config".source = ./config;
      "kanshi/config".text = ''
        profile docked {
                output eDP-1 disable
                output "Lenovo Group Limited LEN P24q-20 V306P4GR" mode 2560x1440@74.780Hz position 0,0
        }
        profile laptop {
                output eDP-1 enable
        }
      '';
      "xdg/gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
        gtk-cursor-theme-name=Adwaita
        gtk-key-theme-name=Emacs
        gtk-theme-name=Adwaita
      '';
    };

    location.provider = "geoclue2";
    services.redshift.enable = true;
    services.redshift.package = pkgs.redshift-wlr;

    environment.variables = {
      XCURSOR_THEME = "Adwaita";
      XCURSOR_PATH = mkForce [
        "${pkgs.gnome.adwaita-icon-theme}/share/icons"
      ];
    };

    custom.pipewire.enable = mkDefault true;
    custom.foot.enable = mkDefault true;

    programs.dconf.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
    };

  };

}
