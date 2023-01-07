{ config, lib, pkgs, systemConfig, ... }:
let
  cfg = config.custom.gui;
  lockerCommand = "${pkgs.swaylock}/bin/swaylock --daemonize --indicator-caps-lock --show-keyboard-layout --color '#222222'";

  colors = {
    background = "000000";
    foreground = "ffffff";
    regular0 = "000000";
    regular1 = "ff8059";
    regular2 = "44bc44";
    regular3 = "d0bc00";
    regular4 = "2fafff";
    regular5 = "feacd0";
    regular6 = "00d3d0";
    regular7 = "bfbfbf";
    bright0 = "595959";
    bright1 = "ef8b50";
    bright2 = "70b900";
    bright3 = "c0c530";
    bright4 = "79a8ff";
    bright5 = "b6a0ff";
    bright6 = "6ae4b9";
    bright7 = "ffffff";
  };
in
with lib; {
  options.custom.gui.enable = mkOption {
    type = types.bool;
    default = systemConfig.custom.gui.enable;
  };

  config = mkIf cfg.enable {
    xdg = {
      userDirs = {
        enable = true;
        createDirectories = true;
        extraConfig.XDG_PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
      };
      mimeApps = {
        enable = true;
        defaultApplications = {
          "audio/*" = [ "mpv.desktop" ];
          "image/jpeg" = [ "imv.desktop" ];
          "image/png" = [ "imv.desktop" ];
          "text/*" = [ "nvim.desktop" ];
          "video/*" = [ "mpv.desktop" ];
          "x-scheme-handler/http" = [ "firefox.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
        };
      };
    };

    xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
    home.packages = [ pkgs.wezterm ];

    programs.alacritty = {
      enable = true;
      settings = {
        env.TERM = "xterm-256color";
        font = {
          normal.family = "JetBrains Mono";
          size = 16;
        };
        colors = lib.mapAttrsRecursive (_: color: "#${color}") {
          primary = {
            foreground = colors.foreground;
            background = colors.background;
          };
          normal = {
            black = colors.regular0;
            red = colors.regular1;
            green = colors.regular2;
            yellow = colors.regular3;
            blue = colors.regular4;
            magenta = colors.regular5;
            cyan = colors.regular6;
            white = colors.regular7;
          };
          bright = {
            black = colors.bright0;
            red = colors.bright1;
            green = colors.bright2;
            yellow = colors.bright3;
            blue = colors.bright4;
            magenta = colors.bright5;
            cyan = colors.bright6;
            white = colors.bright7;
          };
        };
        selection.save_to_clipboard = true;
        mouse.hide_when_typing = true;
      };
    };

    programs.foot = {
      enable = true;
      settings = {
        main = {
          term = config.programs.alacritty.settings.env.TERM;
          font = "${config.programs.alacritty.settings.font.normal.family}:size=${toString (config.programs.alacritty.settings.font.size - 6)}";
          selection-target = "clipboard";
          notify-focus-inhibit = "no";
        };
        bell = {
          urgent = "yes";
          command-focused = "yes";
        };
        mouse.hide-when-typing = "yes";
        colors = { alpha = 1.0; } // colors;
      };
    };

    systemd.user.services.yubikey-touch-detector = {
      Unit = {
        Description = "Yubikey Touch Detector";
        PartOf = "sway-session.target";
        After = "sway-session.target";
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify";
      };
      Install.WantedBy = [ "sway-session.target" ];
    };

    home.pointerCursor = {
      package = pkgs.gnome-themes-extra;
      name = "Adwaita";
      size = mkDefault 24;
      x11.enable = true;
    };

    gtk = {
      enable = true;
      theme = { package = pkgs.gnome-themes-extra; name = "Adwaita-dark"; };
      iconTheme = { package = pkgs.gnome-themes-extra; name = "Adwaita"; };
      gtk4 = removeAttrs config.gtk.gtk3 [ "bookmarks" "extraCss" "waylandSupport" ];
    };

    qt = {
      enable = true;
      platformTheme = "gtk";
      style = {
        package = pkgs.adwaita-qt;
        name = "adwaita-dark";
      };
    };

    programs.mako = {
      enable = true;
      anchor = "top-right";
      defaultTimeout = 10000;
      font = "${toString config.wayland.windowManager.sway.config.fonts.names} ${toString config.wayland.windowManager.sway.config.fonts.size}";
      height = 1000;
      icons = true;
      layer = "overlay";
      width = 500;
    };

    xdg.configFile."gobar/gobar.yaml".source = (pkgs.formats.yaml { }).generate "gobar.yaml" {
      colorVariant = "dark";
      modules = (
        optional config.custom.laptop.enable
          { module = "battery"; }
      ) ++ [
        { module = "network"; pattern = "(en|eth|wlp|wlan|wg)+"; }
        { module = "memory"; }
        { module = "datetime"; timezones = [ "Local" "UTC" ]; }
      ];
    };

    services.gpg-agent = {
      pinentryFlavor = null;
      extraConfig =
        let
          pinentryProgram = pkgs.symlinkJoin {
            name = "pinentry-bemenu";
            buildInputs = [ pkgs.makeWrapper ];
            paths = [ pkgs.pinentry-bemenu ];
            postBuild = ''
              wrapProgram $out/bin/pinentry-bemenu --set BEMENU_OPTS "${systemConfig.environment.variables.BEMENU_OPTS}"
            '';
          };
        in
        ''
          pinentry-program ${pinentryProgram}/bin/pinentry-bemenu
        '';
    };

    services.swayidle = {
      enable = true;
      events = [
        { event = "before-sleep"; command = lockerCommand; }
        { event = "lock"; command = lockerCommand; }
        { event = "after-resume"; command = "${pkgs.sway}/bin/swaymsg 'output * dpms on'"; }
      ];
      timeouts = [
        { timeout = 300; command = lockerCommand; }
        {
          timeout = 570;
          command = toString (pkgs.writeShellScript "swayidle-notify" ''
            ${pkgs.libnotify}/bin/notify-send 'swayidle' 'screen will turn off in 30 seconds...'
          '');
        }
        {
          timeout = 600;
          command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
          resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
        }
      ]
      ++
      optional config.custom.laptop.enable {
        timeout = 900;
        command = toString (pkgs.writeShellScript "laptop-conditional-suspend" ''
          if [[ "$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/AC/online)" -ne 1 ]]; then
            echo "laptop is not on AC, suspending"
            ${pkgs.systemd}/bin/systemctl suspend
          else
            echo "laptop is on AC, not suspending"
          fi
        '');
      };
    };

    services.gammastep = {
      enable = true;
      provider = "geoclue2";
    };

    services.kanshi.enable = config.custom.laptop.enable;

    systemd.user.services.clipman = {
      Unit = {
        Description = "Clipboard manager";
        Documentation = "man:clipman(1)";
        PartOf = "sway-session.target";
        After = "sway-session.target";
      };
      Service = {
        Type = "simple";
        Environment = [ "WAYLAND_DEBUG=1" "PATH=${makeBinPath [ pkgs.wl-clipboard ]}" ];
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text/plain --watch ${pkgs.clipman}/bin/clipman store";
      };
      Install.WantedBy = [ "sway-session.target" ];
    };

    systemd.user.sockets.wob = {
      Socket = {
        ListenFIFO = "%t/wob.sock";
        SocketMode = "0600";
      };
      Install.WantedBy = [ "sockets.target" ];
    };

    systemd.user.services.wob = {
      Unit = {
        Description = "A lightweight overlay volume/backlight/progress/anything bar for Wayland";
        Documentation = "man:wob(1)";
        PartOf = "sway-session.target";
        After = "sway-session.target";
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        StandardInput = "socket";
        ExecStart = "${pkgs.wob}/bin/wob";
      };
      Install.WantedBy = [ "sway-session.target" ];
    };

    wayland.windowManager.sway = {
      enable = true;
      inherit (systemConfig.programs.sway)
        extraSessionCommands extraOptions wrapperFeatures;
      config =
        let
          mod = config.wayland.windowManager.sway.config.modifier;
        in
        {
          seat."*".xcursor_theme = "${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}";
          startup = [ ];
          output."*".background = "#222222 solid_color";
          input =
            let
              mouseSettings = { accel_profile = "flat"; };
              keyboardSettings = { xkb_options = systemConfig.services.xserver.xkbOptions; };
              touchpadSettings = {
                dwt = "enabled";
                middle_emulation = "enabled";
                natural_scroll = "enabled";
                tap = "enabled";
              };
            in
            {
              "113:16461:Logitech_K400_Plus" = keyboardSettings // touchpadSettings // { xkb_options = "ctrl:nocaps"; };
              "type:keyboard" = keyboardSettings;
              "type:pointer" = mouseSettings;
              "type:touchpad" = touchpadSettings;
            };
          assigns = {
            "6" = [{ title = "FreeRDP"; }];
            "7" = [{ title = "pipe:xwayland-mirror"; }];
          };
          window.commands = [
            {
              criteria.app_id = "^chrome-.*__.*";
              command = "shortcuts_inhibitor disable";
            }
            {
              criteria.title = "Firefox — Sharing Indicator";
              command = "kill";
            }
          ];
          floating.criteria = [
            { title = "^FreeRDP$"; }
            { title = "^[pP]icture.in.[pP]icture$"; }
            { title = "^(Zoom Cloud Meetings|zoom)$"; }
            { title = "^QEMU.*$"; }
            { title = "^pipe:xwayland-mirror$"; }
          ];
          fonts = {
            names = [ "JetBrains Mono" ];
            size = 12.0;
          };
          terminal = "${pkgs.alacritty}/bin/alacritty";
          menu = "${pkgs.bemenu}/bin/bemenu-run";
          modifier = "Mod4";
          workspaceLayout = "stacking";
          workspaceAutoBackAndForth = true;
          defaultWorkspace = "workspace number 1";
          focus.forceWrapping = true;
          window = { hideEdgeBorders = "smart"; titlebar = true; };
          keybindings = {
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
            "${mod}+Control+l" = "exec ${lockerCommand}";
            "${mod}+Control+space" = "exec ${pkgs.mako}/bin/makoctl dismiss --all";
            "${mod}+Down" = "focus down";
            "${mod}+Left" = "focus left";
            "${mod}+Print" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify save window";
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
            "${mod}+Shift+Print" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify save area";
            "${mod}+Shift+Right" = "move right";
            "${mod}+Shift+Up" = "move up";
            "${mod}+Shift+b" = "bar mode toggle";
            "${mod}+Shift+c" = "exec ${pkgs.wl-color-picker}/bin/wl-color-picker";
            "${mod}+Shift+e" = "exec ${pkgs.sway}/bin/swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' '${pkgs.systemd}/bin/systemctl --user stop sway-session.target && ${pkgs.sway}/bin/swaymsg exit'";
            "${mod}+Shift+h" = "move left";
            "${mod}+Shift+j" = "move down";
            "${mod}+Shift+k" = "move up";
            "${mod}+Shift+l" = "move right";
            "${mod}+Shift+minus" = "move scratchpad";
            "${mod}+Shift+q" = "kill";
            "${mod}+Shift+r" = "reload";
            "${mod}+Shift+s" = "sticky toggle";
            "${mod}+Shift+space" = "floating toggle";
            "${mod}+Tab" = "workspace back_and_forth";
            "${mod}+Up" = "focus up";
            "${mod}+a" = "focus parent";
            "${mod}+b" = "split h";
            "${mod}+c" = "exec ${pkgs.clipman}/bin/clipman pick --tool=bemenu";
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
            "Print" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify save output";
            "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5% && ${pkgs.pulseaudio}/bin/pactl get-sink-volume @DEFAULT_SINK@ | head -n 1| awk '{print substr($5, 1, length($5)-1)}' > $XDG_RUNTIME_DIR/wob.sock";
            "XF86AudioMicMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            "XF86AudioMute" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle && (${pkgs.pamixer}/bin/pamixer --get-mute && echo 0 > $XDG_RUNTIME_DIR/wob.sock) || ${pkgs.pamixer}/bin/pamixer --get-volume > $XDG_RUNTIME_DIR/wob.sock";
            "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5% && ${pkgs.pulseaudio}/bin/pactl get-sink-volume @DEFAULT_SINK@ | head -n 1| awk '{print substr($5, 1, length($5)-1)}' > $XDG_RUNTIME_DIR/wob.sock";
            "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%- | sed -En 's/.*\\(([0-9]+)%\\).*/\\1/p' > $XDG_RUNTIME_DIR/wob.sock";
            "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set +5% | sed -En 's/.*\\(([0-9]+)%\\).*/\\1/p' > $XDG_RUNTIME_DIR/wob.sock";
          };
          modes = {
            resize = {
              "${mod}+r" = "mode default";
              Down = "resize grow height 10 px";
              Escape = "mode default";
              Left = "resize shrink width 10 px";
              Return = "mode default";
              Right = "resize grow width 10 px";
              Up = "resize shrink height 10 px";
              h = "resize shrink width 10 px";
              j = "resize grow height 10 px";
              k = "resize shrink height 10 px";
              l = "resize grow width 10 px";
            };
          };
          bars = [{
            fonts = config.wayland.windowManager.sway.config.fonts;
            mode = "dock";
            position = "top";
            statusCommand = "${pkgs.gobar}/bin/gobar";
            trayOutput = "*";
            extraConfig = ''
              height 30
            '';
          }];
        };
      swaynag = {
        enable = true;
        settings."<config>".font = "${toString config.wayland.windowManager.sway.config.fonts.names} ${toString config.wayland.windowManager.sway.config.fonts.size}";
      };
      extraConfig = optionalString
        (
          config.custom.laptop.enable &&
            config.services.kanshi.enable &&
            config.services.kanshi.profiles != { }
        ) ''
        set $laptop eDP-1
        bindswitch --reload --locked lid:on output $laptop disable
        bindswitch --reload --locked lid:off output $laptop enable
      '' + ''
        include /etc/sway/config.d/*
      '';
    };
  };
}
