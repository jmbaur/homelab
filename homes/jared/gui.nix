{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
{
  options.custom.gui.enable = lib.mkEnableOption "Enable gui configs";
  config = lib.mkIf cfg.enable {
    home.sessionVariables.NIXOS_OZONE_WL = "1";
    home.packages = with pkgs; [
      bitwarden
      element-desktop
      firefox-wayland
      google-chrome
      grim
      hack-font
      imv
      mpv
      obs-studio
      pinentry-gnome
      signal-desktop
      slack
      slurp
      spotify
      virt-manager
      wf-recorder
      wl-clipboard
      wl-color-picker
      zathura
      zoom-us
    ];

    services.gpg-agent.pinentryFlavor = "gnome3";

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    xsession.pointerCursor = {
      package = pkgs.gnome.gnome-themes-extra;
      name = "Adwaita";
      size = 16;
    };

    gtk = {
      enable = true;
      gtk3.extraConfig = {
        gtk-theme-name = "Adwaita";
        gtk-key-theme-name = "Emacs";
      };
      gtk4 = removeAttrs config.gtk.gtk3 [ "bookmarks" "extraCss" "waylandSupport" ];
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = with config.gtk.gtk3.extraConfig; {
        gtk-theme = gtk-theme-name;
        gtk-key-theme = gtk-key-theme-name;
      };
    };

    programs.kitty = {
      enable = true;
      font = {
        package = pkgs.hack-font;
        name = "Hack";
        size = 16;
      };
      settings = {
        cursor = "#fd28ff";
        term = "xterm-256color";
        copy_on_select = true;
        scrollback_lines = 10000;
        enable_audio_bell = false;
        update_check_interval = 0;
      };
    };

    fonts.fontconfig.enable = true;

    programs.foot = {
      enable = true;
      settings = {
        main = {
          term = config.programs.kitty.settings.term;
          font = "${config.programs.kitty.font.name}:size=${toString (config.programs.kitty.font.size - 6)}";
        };
        mouse.hide-when-typing = "yes";
      };
    };

    services.swayidle = {
      enable = true;
      events = [
        { event = "lock"; command = "swaylock"; }
        { event = "before-sleep"; command = "loginctl lock-session"; }
      ];
      timeouts = [{ timeout = 1800; command = "swaylock"; }];
    };

    services.kanshi = {
      enable = true;
    };

    services.gammastep = {
      enable = true;
      provider = "geoclue2";
    };

    programs.i3status = {
      enable = true;
      general = {
        colors = false;
        interval = 1;
      };
    };

    programs.mako = {
      enable = true;
      defaultTimeout = 5000;
      font = "${toString config.wayland.windowManager.sway.config.fonts.names} ${toString config.wayland.windowManager.sway.config.fonts.size}";
      iconPath = "${pkgs.gnome.gnome-themes-extra}/share/icons";
    };

    wayland.windowManager.sway = {
      enable = true;
      config = {
        floating.criteria = [{ class = "zoom"; }];
        fonts = { names = [ config.programs.kitty.font.name ]; size = 12.0; style = "Regular"; };
        menu = "${pkgs.bemenu}/bin/bemenu-run --ignorecase --line-height 25 --fn '${
          toString config.wayland.windowManager.sway.config.fonts.names
        } ${
          toString config.wayland.windowManager.sway.config.fonts.size
        }' | ${pkgs.findutils}/bin/xargs swaymsg exec --";
        terminal = "${pkgs.kitty}/bin/kitty";
        modifier = "Mod4";
        window = {
          hideEdgeBorders = "smart";
          titlebar = true;
        };
        input = {
          "1:1:AT_Translated_Set_2_keyboard" = {
            xkb_options = "ctrl:nocaps";
          };
          "1739:0:Synaptics_TM3276-022" = {
            tap = "enabled";
            dwt = "enabled";
            natural_scroll = "enabled";
          };
        };
        seat."*".xcursor_theme = "${config.xsession.pointerCursor.name} ${toString config.xsession.pointerCursor.size}";
        keybindings =
          let
            mod = config.wayland.windowManager.sway.config.modifier;
          in
          lib.mkOptionDefault {
            "${mod}+Shift+s" = "sticky toggle";
            "${mod}+Tab" = "workspace back_and_forth";
            "${mod}+p" = "exec ${config.wayland.windowManager.sway.config.menu}";
            "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
            "XF86AudioMicMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            "XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
            "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
            "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
            "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +5%";
          };
        bars = [{
          fonts = config.wayland.windowManager.sway.config.fonts;
          position = "top";
        }];
      };
      extraConfig = ''
        workspace_auto_back_and_forth yes
      '';
    };

  };
}

