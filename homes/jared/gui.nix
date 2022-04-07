{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
{
  options.custom.gui = {
    enable = lib.mkEnableOption "Enable gui configs";
    desktop.enable = lib.mkEnableOption "Enable gui configs tailored for a desktop";
    laptop.enable = lib.mkEnableOption "Enable gui configs tailored for a laptop";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      bitwarden
      ddcutil
      element-desktop
      firefox
      google-chrome
      hack-font
      keybase
      libnotify
      mpv
      obs-studio
      pulsemixer
      signal-desktop
      slack
      spotify
      ventoy-bin
      virt-manager
      xdg-utils
      yubikey-manager
      yubikey-personalization
      # zathura # currently broken
      zoom-us
    ];

    services.gpg-agent = {
      pinentryFlavor = "gnome3";
      # extraConfig = ''
      #   pinentry-program ${bemenuWithArgs}/bin/pinentry-bemenu
      # '';
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

    programs.vscode = {
      enable = true;
      # package = pkgs.vscode-fhs;
      mutableExtensionsDir = false;
      extensions = with pkgs.vscode-extensions; [
        vscodevim.vim
        ms-vsliveshare.vsliveshare
      ];
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

    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" ];
    };
    services.clipmenu.enable = true;
    services.redshift = {
      enable = true;
      provider = "geoclue2";
    };

    xsession.windowManager.i3 = {
      enable = true;
      config = {
        floating.criteria = [{ class = "^zoom$"; }];
        fonts = { names = [ config.programs.kitty.font.name ]; size = 12.0; style = "Regular"; };
        # menu = "${bemenuWithArgs}/bin/bemenu-run";
        terminal = "${pkgs.kitty}/bin/kitty";
        modifier = "Mod4";
        window = {
          hideEdgeBorders = "smart";
          titlebar = true;
        };
        defaultWorkspace = "workspace number 1";
        keybindings =
          let
            mod = config.xsession.windowManager.i3.config.modifier;
          in
          {
            "${mod}+Return" = "exec ${config.xsession.windowManager.i3.config.terminal}";
            "${mod}+Shift+q" = "kill";
            "${mod}+h" = "focus left";
            "${mod}+j" = "focus down";
            "${mod}+k" = "focus up";
            "${mod}+l" = "focus right";
            "${mod}+Left" = "focus left";
            "${mod}+Down" = "focus down";
            "${mod}+Up" = "focus up";
            "${mod}+Right" = "focus right";
            "${mod}+Shift+h" = "move left";
            "${mod}+Shift+j" = "move down";
            "${mod}+Shift+k" = "move up";
            "${mod}+Shift+l" = "move right";
            "${mod}+Shift+Left" = "move left";
            "${mod}+Shift+Down" = "move down";
            "${mod}+Shift+Up" = "move up";
            "${mod}+Shift+Right" = "move right";
            "${mod}+b" = "split h";
            "${mod}+v" = "split v";
            "${mod}+f" = "fullscreen toggle";
            "${mod}+s" = "layout stacking";
            "${mod}+w" = "layout tabbed";
            "${mod}+e" = "layout toggle split";
            "${mod}+Shift+space" = "floating toggle";
            "${mod}+space" = "focus mode_toggle";
            "${mod}+a" = "focus parent";
            "${mod}+Shift+minus" = "move scratchpad";
            "${mod}+minus" = "scratchpad show";
            "${mod}+1" = "workspace number 1";
            "${mod}+2" = "workspace number 2";
            "${mod}+3" = "workspace number 3";
            "${mod}+4" = "workspace number 4";
            "${mod}+5" = "workspace number 5";
            "${mod}+6" = "workspace number 6";
            "${mod}+7" = "workspace number 7";
            "${mod}+8" = "workspace number 8";
            "${mod}+9" = "workspace number 9";
            "${mod}+0" = "workspace number 10";
            "${mod}+Shift+1" = "move container to workspace number 1";
            "${mod}+Shift+2" = "move container to workspace number 2";
            "${mod}+Shift+3" = "move container to workspace number 3";
            "${mod}+Shift+4" = "move container to workspace number 4";
            "${mod}+Shift+5" = "move container to workspace number 5";
            "${mod}+Shift+6" = "move container to workspace number 6";
            "${mod}+Shift+7" = "move container to workspace number 7";
            "${mod}+Shift+8" = "move container to workspace number 8";
            "${mod}+Shift+9" = "move container to workspace number 9";
            "${mod}+Shift+0" = "move container to workspace number 10";
            "${mod}+Shift+c" = "reload";
            "${mod}+Shift+r" = "restart";
            "${mod}+Shift+e" = "exec i3-nagbar -t warning -m 'Do you want to exit i3?' -b 'Yes' 'i3-msg exit'";
            "${mod}+r" = "mode resize";
            "${mod}+Shift+s" = "sticky toggle";
            "${mod}+Tab" = "workspace back_and_forth";
            # "${mod}+c" = "exec ${pkgs.clipman}/bin/clipman pick --tool=CUSTOM --tool-args=${bemenuWithArgs}/bin/bemenu";
            "${mod}+p" = "exec ${config.xsession.windowManager.i3.config.menu}";
            "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
            "XF86AudioMicMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            "XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
            "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
            "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
            "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +5%";
          };
        bars = [{
          fonts = config.xsession.windowManager.i3.config.fonts;
          position = "top";
          trayOutput = "primary";
        }];
      };
      extraConfig = ''
        workspace_auto_back_and_forth yes
      '';
    };
  };
}
