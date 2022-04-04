{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
  bemenuWithArgs = pkgs.symlinkJoin {
    name = "bemenuWithArgs";
    buildInputs = [ pkgs.makeWrapper ];
    paths = [ pkgs.bemenu pkgs.pinentry-bemenu ];
    postBuild = ''
      for cmd in "bemenu" "bemenu-run" "pinentry-bemenu"; do
        wrapProgram $out/bin/$cmd \
          --add-flags "--ignorecase" \
          --add-flags "--list 10" \
          --add-flags "--line-height 25" \
          --add-flags "--fn ${toString config.wayland.windowManager.sway.config.fonts.names} ${toString config.wayland.windowManager.sway.config.fonts.size}"
      done
    '';
  };
in
{
  options.custom.gui = {
    enable = lib.mkEnableOption "Enable gui configs";
    desktop.enable = lib.mkEnableOption "Enable gui configs tailored for a desktop";
    laptop.enable = lib.mkEnableOption "Enable gui configs tailored for a laptop";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (wrapOBS { plugins = with pkgs.obs-studio-plugins; [ wlrobs ]; })
      bitwarden
      element-desktop
      firefox-wayland
      google-chrome
      grim
      hack-font
      imv
      mpv
      opentaxsolver
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

    services.gpg-agent = {
      pinentryFlavor = null;
      extraConfig = ''
        pinentry-program ${bemenuWithArgs}/bin/pinentry-bemenu
      '';
    };

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
        gtk-theme-name = "Adwaita-dark";
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
      settings =
        let
          kitty-gruvbox-dark = builtins.fetchurl {
            url = "https://raw.githubusercontent.com/wdomitrz/kitty-gruvbox-theme/master/gruvbox_dark.conf";
            sha256 = "0n1w1ycb10fc97jjjymf2bcg591vaxmk6kxnvfbj41b35s6c734m";
          };
        in
        {
          copy_on_select = true;
          enable_audio_bell = false;
          include = kitty-gruvbox-dark;
          scrollback_lines = 10000;
          term = "xterm-256color";
          update_check_interval = 0;
        };
    };

    fonts.fontconfig.enable = true;

    programs.foot = {
      enable = true;
      settings = {
        main = {
          include = "${pkgs.foot.src}/themes/gruvbox-dark";
          term = config.programs.kitty.settings.term;
          font = "${config.programs.kitty.font.name}:size=${toString (config.programs.kitty.font.size - 6)}";
        };
        mouse.hide-when-typing = "yes";
      };
    };

    services.swayidle = {
      enable = true;
      events = [
        { event = "lock"; command = "swaylock -c 000000"; }
        { event = "before-sleep"; command = "loginctl lock-session"; }
      ];
      timeouts = [{ timeout = 1800; command = "swaylock -c 000000"; }];
    };

    services.kanshi = lib.mkIf cfg.laptop.enable {
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
      modules =
        {
          ipv6.enable = true;

          "wireless _first_" = {
            enable = cfg.laptop.enable;
            settings = {
              format_down = "W: down";
              format_up = "W: (%quality at %essid) %ip";
            };
          };

          "ethernet _first_" = {
            enable = true;
            settings = {
              format_down = "E: down";
              format_up = "E: %ip (%speed)";
            };
          };

          "battery all" = {
            enable = cfg.laptop.enable;
            settings.format = "%status %percentage %remaining";
          };

          "disk /" = {
            enable = true;
            settings.format = "%avail";
          };

          load = {
            enable = true;
            settings.format = "%1min";
          };

          memory = {
            enable = true;
            settings = {
              format = "%used | %available";
              format_degraded = "MEMORY < %available";
              threshold_degraded = "1G";
            };
          };

          "tztime local" = {
            enable = true;
            settings.format = "%F %T";
          };

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
        floating.criteria = [
          { title = "Firefox — Sharing Indicator"; }
          { title = "Picture-in-Picture"; }
          # TODO(jared): create regexp that matches all zoom windows
          { title = "Zoom Cloud Meetings"; }
          { title = "Zoom Meeting"; }
          { title = "zoom"; }
        ];
        fonts = { names = [ config.programs.kitty.font.name ]; size = 12.0; style = "Regular"; };
        menu = "${bemenuWithArgs}/bin/bemenu-run";
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
            "${mod}+c" = "exec ${pkgs.clipman}/bin/clipman pick --tool=CUSTOM --tool-args=${bemenuWithArgs}/bin/bemenu";
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
          trayOutput = "*";
        }];
      };
      extraConfig = ''
        workspace_auto_back_and_forth yes
      '';
    };

    systemd.user.services.clipman = {
      Unit = {
        Description = "Clipboard manager";
        Documentation = "man:clipman(1)";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store";
        Restart = "always";
      };

      Install.WantedBy = [ config.services.kanshi.systemdTarget ];
    };

  };
}
