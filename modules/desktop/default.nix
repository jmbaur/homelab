{ config, lib, pkgs, ... }:
let
  cfg = config.custom.desktop;
in

with lib;

{

  options = {
    custom.desktop.enable = mkEnableOption "Enable custom desktop config";
  };

  config = mkIf cfg.enable {
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraSessionCommands = ''
        export GTK_THEME=Adwaita-dark
        export XCURSOR_THEME=Adwaita
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
        alacritty
        bemenu
        brightnessctl
        clipman
        fnott
        foot
        fuzzel
        gobar
        grim
        kanshi
        kitty
        mako
        pulseaudio
        slurp
        swayidle
        swaylock
        wev
        wl-clipboard
        wofi
        wtype
        zathura
      ];
    };
    environment.variables.XCURSOR_PATH = lib.mkForce [ "${pkgs.gnome.adwaita-icon-theme}/share/icons" ];
    environment.etc = {
      "xdg/gtk-2.0/gtkrc".source = pkgs.writeText "gtkrc" ''
        gtk-theme-name = "Adwaita-dark"
      '';
      "xdg/gtk-3.0/settings.ini".source = pkgs.writeText "settings.ini" ''
        [Settings]
        gtk-theme-name = Adwaita-dark
        gtk-application-prefer-dark-theme = true
        gtk-key-theme-name = Emacs
      '';
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command =
            let
              configFile = pkgs.writeText "sway-config" (builtins.readFile ./sway.conf);
            in
            "${pkgs.greetd.tuigreet}/bin/tuigreet --issue --time --cmd 'sway --config ${configFile}'";
        };
      };
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
    };

    programs.wshowkeys.enable = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
      media-session.config.bluez-monitor.rules = [
        {
          # Matches all cards
          matches = [{ "device.name" = "~bluez_card.*"; }];
          actions = {
            "update-props" = {
              "bluez5.reconnect-profiles" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
              # mSBC is not expected to work on all headset + adapter combinations.
              "bluez5.msbc-support" = true;
              # SBC-XQ is not expected to work on all headset + adapter combinations.
              "bluez5.sbc-xq-support" = true;
            };
          };
        }
        {
          matches = [
            # Matches all sources
            { "node.name" = "~bluez_input.*"; }
            # Matches all outputs
            { "node.name" = "~bluez_output.*"; }
          ];
          actions = {
            "node.pause-on-idle" = false;
          };
        }
      ];
    };

    systemd.user.targets.sway-session = {
      description = "Sway compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    systemd.user.services.kanshi = {
      description = "Kanshi output autoconfig ";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig =
        let
          configFile = pkgs.writeText "kanshi-config" ''
            profile {
              output eDP-1 enable scale 1
            }
          '';
        in
        {
          ExecStart = ''
            ${pkgs.kanshi}/bin/kanshi --config ${configFile}
          '';
          RestartSec = 5;
          Restart = "always";
        };
    };

    systemd.user.services.swayidle = {
      description = "Idle Manager for Wayland";
      documentation = [ "man:swayidle(1)" ];
      wantedBy = [ "sway-session.target" ];
      partOf = [ "graphical-session.target" ];
      path = [ pkgs.bash ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.swayidle}/bin/swayidle -w \
            timeout 300 '${pkgs.swaylock}/bin/swaylock' \
            timeout 600 '${pkgs.sway}/bin/swaymsg "output * dpms off"' \
            resume '${pkgs.sway}/bin/swaymsg "output * dpms on"'
        '';
      };
    };

    systemd.user.services.wlsunset = {
      description = "Day/night gamma adjustments for Wayland compositors";
      documentation = [ "man:wlsunset(1)" ];
      wantedBy = [ "sway-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.wlsunset}/bin/wlsunset
        '';
      };
    };

    systemd.user.services.clipman = {
      description = "A clipboard manager for Wayland";
      wantedBy = [ "sway-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store --no-persist
        '';
      };
    };

  };

}
