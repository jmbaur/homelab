{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
{
  options.custom.gui.enable = lib.mkEnableOption "Enable gui configs";
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      bitwarden
      chromium
      element-desktop
      firefox
      mpv
      obs-studio
      signal-desktop
      slack
      spotify
      teams
      virt-manager
      wireshark
      zathura
      zoom-us
    ];

    services.gpg-agent.pinentryFlavor = "gnome3";

    gtk = rec {
      enable = true;
      gtk3.extraConfig = {
        gtk-key-theme-name = "Emacs";
        gtk-application-prefer-dark-theme = true;
      };
      gtk4 = gtk3;
    };

    programs.kitty = {
      enable = true;
      font.name = "Hack";
      font.package = pkgs.hack-font;
      font.size = 14;
      theme = "modus-vivendi";
      settings = {
        copy_on_select = "yes";
        enable_audio_bell = "no";
        mouse_hide_wait = 0;
        term = "xterm-256color";
        update_check_interval = 0;
      };
    };

    xresources = {
      properties = { "XTerm.vt100.faceName" = "Hack:size=14:antialias=true"; };
    };

    programs.rofi = {
      enable = true;
      plugins = [ pkgs.rofi-emoji ];
      extraConfig.modi = "drun,emoji,ssh";
      font = "Hack 12";
      terminal = "${pkgs.kitty}/bin/kitty";
    };

    xsession = {
      enable = true;
      pointerCursor = {
        package = pkgs.gnome.gnome-themes-extra;
        name = "Adwaita";
        size = 16;
      };
      initExtra = ''
        ${pkgs.xorg.xsetroot}/bin/xsetroot -solid "#222222"
      '';
      windowManager.i3 = {
        enable = true;
        config =
          let
            mod = config.xsession.windowManager.i3.config.modifier;
          in
          {
            terminal = "kitty";
            modifier = "Mod4";
            defaultWorkspace = "workspace number 1";
            fonts = { names = [ "Hack" ]; size = 10.0; };
            floating.criteria = [{ class = "zoom"; }];
            keybindings =
              lib.mkOptionDefault {
                "${mod}+Control+space" = "exec ${pkgs.dunst}/bin/dunstctl close-all";
                "${mod}+Shift+h" = "move left";
                "${mod}+Shift+j" = "move down";
                "${mod}+Shift+k" = "move up";
                "${mod}+Shift+l" = "move right";
                "${mod}+Shift+s" = "sticky toggle";
                "${mod}+Tab" = "workspace back_and_forth";
                "${mod}+c" = "exec ${pkgs.clipmenu}/bin/clipmenu";
                "${mod}+h" = "focus left";
                "${mod}+j" = "focus down";
                "${mod}+k" = "focus up";
                "${mod}+l" = "focus right";
                "${mod}+p" = "exec rofi -show drun"; # do not give full nix store path to rofi, custom `-modi` options will not work
                "${mod}+r" = "mode resize";
                "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
                "XF86AudioMicMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";
                "XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
                "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
              };
            modes.resize = {
              "h" = "resize grow width 10 px or 10 ppt";
              "j" = "resize shrink height 10 px or 10 ppt";
              "k" = "resize grow height 10 px or 10 ppt";
              "l" = "resize shrink width 10 px or 10 ppt";
              "${mod}+r" = "mode default"; # toggle
              "Escape" = "mode default";
            };
            bars = [{
              fonts = config.xsession.windowManager.i3.config.fonts;
              statusCommand = "${pkgs.i3status}/bin/i3status";
              trayOutput = "primary";
              position = "top";
            }];
          };
        extraConfig = ''
          workspace_auto_back_and_forth yes
          for_window [all] title_window_icon on
        '';
      };
    };

    home.sessionVariables.CM_LAUNCHER = "rofi";
    services.clipmenu.enable = true;

    services.dunst = {
      enable = true;
      iconTheme = {
        package = pkgs.gnome.gnome-themes-extra;
        name = "Adwaita";
      };
      settings = {
        global = {
          geometry = "300x5-30+50";
          font = "Hack 12";
        };
      };
    };

    services.redshift = {
      enable = true;
      provider = "geoclue2";
    };

    services.screen-locker = {
      enable = true;
      lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 222222";
    };

  };
}
