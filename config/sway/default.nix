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
    programs.dconf.enable = true;
    programs.wshowkeys.enable = true;

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
      extraPackages = with pkgs;
        let
          swaystatus = writeShellScriptBin "swaystatus" ''
            while true; do
              printf "%d%% | %s" "$(cat /sys/class/power_supply/BAT0/capacity)" "$(date +'%F %T')"
              sleep 1
            done
          '';
        in
        [
          bemenu
          brightnessctl
          clipman
          fuzzel
          glib
          grim
          i3status-rust
          kanshi-wrapped
          mako
          pulseaudio
          slurp
          swayidle
          swaylock
          swaystatus
          v4l-utils
          wf-recorder
          wl-clipboard
          wlr-randr
          xorg.xeyes
          xwayland
        ];
    };

    environment.etc = {
      "sway/config".source = ./config;
      "xdg/gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
        gtk-theme-name=Adwaita
        gtk-icon-theme-name=Adwaita
        gtk-cursor-theme-name=Adwaita
        gtk-key-theme-name=Emacs
        gtk-font-name=Hack
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

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.greetd}/bin/agreety --cmd sway";
        };
      };
    };

    custom.pipewire.enable = mkDefault true;
    custom.foot.enable = mkDefault true;

    xdg.portal = {
      enable = true;
      wlr = {
        enable = true;
        # settings = {
        #   screencast = {
        #     max_fps = 30;
        #     exec_before = "disable_notifications.sh";
        #     exec_after = "enable_notifications.sh";
        #     chooser_type = "simple";
        #     chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
        #   };
        # };
      };
    };

  };

}
