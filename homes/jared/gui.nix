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
      # zathura # currently broken
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
      st
      ventoy-bin
      virt-manager
      xdg-utils
      yubikey-manager
      yubikey-personalization
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

    # programs.rofi = {
    #   enable = true;
    #   font = "${toString config.xsession.windowManager.i3.config.fonts.names} ${toString config.xsession.windowManager.i3.config.fonts.size}";
    #   plugins = with pkgs; [ rofi-emoji rofi-vpn rofi-power-menu ];
    #   terminal = "${pkgs.kitty}/bin/kitty";
    #   theme = builtins.readFile (builtins.fetchurl {
    #     url = "https://raw.githubusercontent.com/jordiorlando/base16-rofi/master/themes/base16-zenburn.config";
    #     sha256 = "020hwsiwm6iwv5xy2pj84hyb0qykkcyknng047ib0gcp9v7gqqvq";
    #   });
    # };

    programs.vscode = {
      enable = true;
      mutableExtensionsDir = false;
      extensions = with pkgs.vscode-extensions; [
        asvetliakov.vscode-neovim
        bbenoist.nix
        ms-vsliveshare.vsliveshare
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [{
        name = "zenburn";
        publisher = "ryanolsonx";
        version = "1.0.1";
        sha256 = "sha256-P37Q3IXOg6xESdVHjBWTvSid9L2IjvVKt7qpPV0qYb0=";
      }];
      userSettings = {
        "breadcrumbs.enabled" = false;
        "editor.fontFamily" = "Hack";
        "editor.fontSize" = config.programs.kitty.font.size + 4;
        "editor.minimap.enabled" = false;
        "extensions.ignoreRecommendations" = true;
        "telemetry.telemetryLevel" = "off";
        "vscode-neovim.neovimExecutablePaths.linux" = "${pkgs.neovim-unwrapped}/bin/nvim";
        "workbench.colorTheme" = "Zenburn";
      };
    };

    programs.kitty = {
      enable = true;
      theme = "Zenburn";
      font = {
        package = pkgs.hack-font;
        name = "Hack";
        size = 16;
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
      enableDefault = false;
      general = { colors = false; interval = 1; };
      modules = {
        "tztime local" = {
          enable = true;
          position = 1;
          settings.format = "%F %T";
        };
      };
    };

    services.blueman-applet.enable = true;
    services.cbatticon.enable = cfg.laptop.enable;
    services.network-manager-applet.enable = true;
    services.pasystray.enable = true;
    services.gnome-keyring = { enable = true; components = [ "secrets" ]; };
    services.clipmenu.enable = true;
    services.redshift = { tray = true; enable = true; provider = "geoclue2"; };
    services.dunst = {
      enable = true;
      iconTheme = {
        package = pkgs.gnome.gnome-themes-extra;
        name = "Adwaita";
        size = "32x32";
      };
      settings.global.font = "${config.programs.kitty.font.name} 12";
    };

    xsession.windowManager.i3 = {
      enable = true;
      config =
        let
          dmenuArgs = "-h 28" + " "
            + "-fn '${toString config.xsession.windowManager.i3.config.fonts.names}:size=${toString config.xsession.windowManager.i3.config.fonts.size}'" + " "
            + "-sb '${config.xsession.windowManager.i3.config.colors.focused.background}'" + " "
            + "-sf  '${config.xsession.windowManager.i3.config.colors.focused.text}'" + " "
            + "-nb '${config.xsession.windowManager.i3.config.colors.unfocused.background}'" + " "
            + "-nf  '${config.xsession.windowManager.i3.config.colors.unfocused.text}'";
        in
        {
          floating.criteria = [{ class = "^zoom$"; }];
          fonts = { names = [ config.programs.kitty.font.name ]; size = 14.0; style = "Regular"; };
          menu = "${pkgs.dmenu}/bin/dmenu_run ${dmenuArgs}";
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
              "${mod}+Return" = "exec ${config.xsession.windowManager.i3.config.terminal}";
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
              "${mod}+Shift+e" = "exec i3-nagbar -t warning -m 'Do you want to exit i3?' -b 'Yes' 'i3-msg exit'";
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
              "${mod}+c" = "exec ${pkgs.clipmenu}/bin/clipmenu ${dmenuArgs}";
              "${mod}+e" = "layout toggle split";
              "${mod}+f" = "fullscreen toggle";
              "${mod}+h" = "focus left";
              "${mod}+j" = "focus down";
              "${mod}+k" = "focus up";
              "${mod}+l" = "focus right";
              "${mod}+minus" = "scratchpad show";
              "${mod}+p" = "exec ${config.xsession.windowManager.i3.config.menu}";
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
