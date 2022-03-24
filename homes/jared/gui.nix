{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
  inherit (pkgs.callPackage ../../lib/kitty-theme-to-nix.nix { }) theme theme-no-octothorpe;
in
{
  options.custom.gui.enable = lib.mkEnableOption "Enable gui configs";
  config = lib.mkIf cfg.enable {
    home.sessionVariables.NIXOS_OZONE_WL = "1";
    home.packages = with pkgs; [
      bitwarden
      chromium
      element-desktop
      firefox-wayland
      obs-studio
      signal-desktop
      slack
      spotify
      teams
      virt-manager
      zoom-us
    ];

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    xsession.pointerCursor = {
      package = pkgs.gnome.gnome-themes-extra;
      name = "Adwaita";
      size = 16;
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = "Adwaita-dark";
        gtk-key-theme = "Emacs";
      };
    };

    programs.kitty = {
      enable = true;
      font = {
        package = pkgs.iosevka-bin;
        name = "Iosevka";
        size = 16;
      };
      theme = "modus-vivendi";
      settings = {
        copy_on_select = true;
        scrollback_lines = 10000;
        enable_audio_bell = false;
        update_check_interval = 0;
      };
    };

    services.swayidle =
      let
        swaylockCmd = "swaylock --color ${theme-no-octothorpe.selection_background}";
      in
      {
        enable = true;
        events = [
          { event = "after-resume"; command = "swaymsg \"output * dpms on\""; }
          { event = "lock"; command = swaylockCmd; }
          { event = "before-sleep"; command = "loginctl lock-session"; }
        ];
        timeouts = [
          { timeout = 1800; command = swaylockCmd; }
          { timeout = 1805; command = "swaymsg \"output * dpms off\""; }
        ];
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
        colors = true;
        color_good = theme.color2;
        color_degraded = theme.color3;
        color_bad = theme.color1;
        interval = 1;
      };
    };

    programs.mako = {
      enable = true;
      backgroundColor = theme.selection_background;
      borderColor = theme.color8;
      defaultTimeout = 5000;
      font = "${builtins.toString config.wayland.windowManager.sway.config.fonts.names} ${builtins.toString config.wayland.windowManager.sway.config.fonts.size}";
      iconPath = "${pkgs.gnome.gnome-themes-extra}/share/icons";
      progressColor = "over ${theme.color2}";
      textColor = theme.foreground;
    };

    wayland.windowManager.sway = {
      enable = true;
      config = {
        fonts = { names = [ "Iosevka" ]; size = 12.0; style = "Regular"; };
        menu = "${pkgs.bemenu}/bin/bemenu-run --ignorecase --line-height 27 --fn '${
          builtins.toString config.wayland.windowManager.sway.config.fonts.names
        } ${
          builtins.toString config.wayland.windowManager.sway.config.fonts.size
        }' --nb '${theme.background}' --tb '${theme.background}' --sb '${theme.background}' | ${pkgs.findutils}/bin/xargs swaymsg exec --";

        # -b, --bottom          appears at the bottom of the screen. (wx)
        # -c, --center          appears at the center of the screen. (wx)
        # -f, --grab            show the menu before reading stdin. (wx)
        # -n, --no-overlap      adjust geometry to not overlap with panels. (w)
        # -m, --monitor         index of monitor where menu will appear. (wx)
        # -H, --line-height     defines the height to make each menu line (0 = default height). (wx)
        # -M, --margin          defines the empty space on either side of the menu. (wx)
        # -W, --width-factor    defines the relative width factor of the menu (from 0 to 1). (wx)
        # --ch                  defines the height of the cursor (0 = scales with line height). (wx)
        # --fn                  defines the font to be used ('name [size]'). (wx)
        # --tb                  defines the title background color. (wx)
        # --tf                  defines the title foreground color. (wx)
        # --fb                  defines the filter background color. (wx)
        # --ff                  defines the filter foreground color. (wx)
        # --nb                  defines the normal background color. (wx)
        # --nf                  defines the normal foreground color. (wx)
        # --hb                  defines the highlighted background color. (wx)
        # --hf                  defines the highlighted foreground color. (wx)
        # --fbb                 defines the feedback background color. (wx)
        # --fbf                 defines the feedback foreground color. (wx)
        # --sb                  defines the selected background color. (wx)
        # --sf                  defines the selected foreground color. (wx)
        # --scb                 defines the scrollbar background color. (wx)
        # --scf                 defines the scrollbar foreground color. (wx)

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
        colors = {
          background = theme.background;
          focused = {
            background = theme.selection_background;
            border = theme.color8;
            childBorder = theme.color8;
            indicator = theme.color7;
            text = theme.foreground;
          };
          urgent = {
            background = theme.color1;
            border = theme.color9;
            childBorder = theme.color9;
            indicator = theme.color7;
            text = theme.color0;
          };
        };
        seat."*".xcursor_theme = "${config.xsession.pointerCursor.name} ${builtins.toString config.xsession.pointerCursor.size}";
        output."*".background = "${theme.selection_background} solid_color";
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
          colors = rec {
            background = theme.background;
            focusedBackground = background;
            activeWorkspace = {
              background = theme.selection_background;
              border = theme.color8;
              text = theme.foreground;
            };
            focusedWorkspace = activeWorkspace;
            inactiveWorkspace = {
              background = theme.color8;
              border = theme.color8;
              text = theme.foreground;
            };
            urgentWorkspace = {
              background = theme.color1;
              border = theme.color9;
              text = theme.color0;
            };
            bindingMode = urgentWorkspace;
            statusline = theme.foreground;
            focusedStatusline = statusline;
            separator = theme.color7;
            focusedSeparator = separator;
          };
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

