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
      extraPackages = with pkgs; [
        bemenu
        brightnessctl
        clipman
        fuzzel
        glib
        grim
        i3status-rust-wrapped
        kanshi-wrapped
        mako-wrapped
        pulseaudio
        slurp
        swayidle
        swaylock
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
        gtk-application-prefer-dark-theme=0
        gtk-theme-name=Adwaita
        gtk-icon-theme-name=Adwaita
        gtk-cursor-theme-name=Adwaita
        gtk-key-theme-name=Emacs
        gtk-font-name=Source Sans Pro
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
