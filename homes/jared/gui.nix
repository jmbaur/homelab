{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
{
  options.custom.gui = {
    enable = lib.mkEnableOption "Enable gui configs";
    laptop = lib.mkEnableOption "Enable gui configs tailored for a laptop";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (wrapOBS { plugins = with obs-studio-plugins; [ wlrobs ]; })
      bitwarden
      cage
      ddcutil
      element-desktop-wayland
      firefox-wayland
      google-chrome
      grim
      hack-font
      keybase
      libnotify
      mpv
      pulsemixer
      signal-desktop
      slack
      slurp
      spotify
      ventoy-bin
      wl-clipboard
      wl-color-picker
      xdg-utils
      yubikey-manager
      yubikey-personalization
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
      mutableExtensionsDir = false;
      extensions = with pkgs.vscode-extensions; [
        asvetliakov.vscode-neovim
        bbenoist.nix
        ms-vsliveshare.vsliveshare
      ];
      userSettings = {
        "breadcrumbs.enabled" = false;
        "editor.fontFamily" = config.programs.kitty.font.name;
        "editor.fontSize" = config.programs.kitty.font.size + 4;
        "editor.minimap.enabled" = false;
        "extensions.ignoreRecommendations" = true;
        "telemetry.telemetryLevel" = "off";
        "vscode-neovim.neovimExecutablePaths.linux" = "${pkgs.neovim-embed}/bin/nvim";
      };
    };

    programs.kitty = {
      enable = true;
      theme = "modus-vivendi";
      font = {
        package = pkgs.hack-font;
        name = "Hack";
        size = 14;
      };
      settings = {
        copy_on_select = true;
        enable_audio_bell = false;
        scrollback_lines = 10000;
        term = "xterm-256color";
        update_check_interval = 0;
      };
    };

    fonts.fontconfig.enable = true;

    programs.i3status = {
      enable = true;
      enableDefault = true;
      general.interval = 1;
    };

    programs.mako = {
      enable = true;
    };

    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" ];
    };

    services.swayidle = {
      enable = true;
      events = [
        { event = "before-sleep"; command = "swaylock -fFc 000000"; }
        { event = "lock"; command = "swaylock -fFc 000000"; }
      ];
      timeouts = [{ timeout = 60; command = "swaylock -fFc 000000"; }];
    };

    services.gammastep = {
      enable = true;
      provider = "geoclue2";
    };

    services.kanshi = {
      enable = cfg.laptop;
    };

    wayland.windowManager.sway = {
      enable = true;
      config = {
        floating.criteria = [
          { title = "^(Zoom Cloud Meetings|zoom)$"; }
          { title = "Firefox — Sharing Indicator"; }
          { title = "Picture-in-Picture"; }
        ];
        fonts = {
          names = [ config.programs.kitty.font.name ];
          size = 12.0;
          style = "Regular";
        };
        menu = "${pkgs.bemenu}/bin/bemenu-run";
        terminal = "${pkgs.kitty}/bin/kitty";
        modifier = "Mod4";
        window = {
          hideEdgeBorders = "smart";
          titlebar = true;
        };
        defaultWorkspace = "workspace number 1";
        keybindings =
          let
            mod = config.wayland.windowManager.sway.config.modifier;
          in
          {
            "${mod}+0" = "workspace number 10";
            "${mod}+1" = "workspace number 1";
            "${mod}+2" = "workspace number 2";
            "${mod}+3" = "workspace number 3";
            "${mod}+4" = "workspace number 4";
            "${mod}+5" = "workspace number 5";
            "${mod}+6" = "workspace number 6";
            "${mod}+7" = "workspace number 7";
            "${mod}+8" = "workspace number 8";
            "${mod}+9" = "workspace number 9";
            "${mod}+Down" = "focus down";
            "${mod}+Left" = "focus left";
            "${mod}+Return" = "exec ${config.wayland.windowManager.sway.config.terminal}";
            "${mod}+Right" = "focus right";
            "${mod}+Shift+0" = "move container to workspace number 10";
            "${mod}+Shift+1" = "move container to workspace number 1";
            "${mod}+Shift+2" = "move container to workspace number 2";
            "${mod}+Shift+3" = "move container to workspace number 3";
            "${mod}+Shift+4" = "move container to workspace number 4";
            "${mod}+Shift+5" = "move container to workspace number 5";
            "${mod}+Shift+6" = "move container to workspace number 6";
            "${mod}+Shift+7" = "move container to workspace number 7";
            "${mod}+Shift+8" = "move container to workspace number 8";
            "${mod}+Shift+9" = "move container to workspace number 9";
            "${mod}+Shift+Down" = "move down";
            "${mod}+Shift+Left" = "move left";
            "${mod}+Shift+Right" = "move right";
            "${mod}+Shift+Up" = "move up";
            "${mod}+Shift+c" = "reload";
            "${mod}+Shift+e" = "exit";
            "${mod}+Shift+h" = "move left";
            "${mod}+Shift+j" = "move down";
            "${mod}+Shift+k" = "move up";
            "${mod}+Shift+l" = "move right";
            "${mod}+Shift+minus" = "move scratchpad";
            "${mod}+Shift+q" = "kill";
            "${mod}+Shift+r" = "restart";
            "${mod}+Shift+s" = "sticky toggle";
            "${mod}+Shift+space" = "floating toggle";
            "${mod}+Tab" = "workspace back_and_forth";
            "${mod}+Up" = "focus up";
            "${mod}+a" = "focus parent";
            "${mod}+b" = "split h";
            # "${mod}+c" = "exec ${pkgs.clipmenu}/bin/clipmenu ${dmenuArgs}";
            "${mod}+e" = "layout toggle split";
            "${mod}+f" = "fullscreen toggle";
            "${mod}+h" = "focus left";
            "${mod}+j" = "focus down";
            "${mod}+k" = "focus up";
            "${mod}+l" = "focus right";
            "${mod}+minus" = "scratchpad show";
            "${mod}+p" = "exec ${config.wayland.windowManager.sway.config.menu}";
            "${mod}+r" = "mode resize";
            "${mod}+s" = "layout stacking";
            "${mod}+space" = "focus mode_toggle";
            "${mod}+v" = "split v";
            "${mod}+w" = "layout tabbed";
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
        workspaceAutoBackAndForth = true;
      };
    };
  };
}
