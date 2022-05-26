{ config, lib, pkgs, ... }:
let
  bemenuWithArgs = pkgs.symlinkJoin {
    name = "bemenuWithArgs";
    buildInputs = [ pkgs.makeWrapper ];
    paths = [ pkgs.bemenu pkgs.pinentry-bemenu ];
    postBuild = ''
      for cmd in "bemenu" "bemenu-run" "pinentry-bemenu"; do
        wrapProgram $out/bin/$cmd \
          --add-flags "--ignorecase" \
          --add-flags "--list 10" \
          --add-flags "--line-height 29" \
          --add-flags "--fn='${toString config.wayland.windowManager.sway.config.fonts.names} ${toString config.wayland.windowManager.sway.config.fonts.size}'"
      done
    '';
  };
in
{
  home.packages = with pkgs; [
    (wrapOBS { plugins = with obs-studio-plugins; [ wlrobs ]; })
    bitwarden
    chromium
    ddcutil
    element-desktop-wayland
    firefox-wayland
    gimp
    iosevka-bin
    keybase
    signal-desktop
    slack
    spotify
    ventoy-bin
    yubikey-manager
    yubikey-personalization
    zoom-us
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  home.pointerCursor = {
    package = pkgs.gnome-themes-extra;
    name = "Adwaita";
    size = 16;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      inherit (config.home.pointerCursor) package;
      name = "${config.home.pointerCursor.name}-dark";
    };
    iconTheme = { inherit (config.home.pointerCursor) package name; };
    gtk3.extraConfig.gtk-key-theme-name = "Emacs";
    gtk4 = removeAttrs config.gtk.gtk3 [ "bookmarks" "extraCss" "waylandSupport" ];
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = with config.gtk.gtk3.extraConfig; {
      gtk-key-theme = gtk-key-theme-name;
    };
  };

  home.file."${config.programs.gpg.homedir}/gpg-agent.conf".text = ''
    pinentry-program ${bemenuWithArgs}/bin/pinentry-bemenu
  '';

  programs.kitty = {
    enable = true;
    font = {
      package = pkgs.iosevka-bin;
      name = "Iosevka";
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

  programs.mako = {
    enable = true;
    defaultTimeout = 5000;
    font = "${toString config.wayland.windowManager.sway.config.fonts.names} ${toString config.wayland.windowManager.sway.config.fonts.size}";
    extraConfig = ''
      [mode=do-not-disturb]
      invisible=1
    '';
  };

  services.swayidle =
    let lockerCommand = "${pkgs.swaylock}/bin/swaylock -fc 000000"; in
    {
      enable = true;
      events = [
        { event = "before-sleep"; command = lockerCommand; }
        { event = "lock"; command = lockerCommand; }
      ];
      timeouts = [
        { timeout = 600; command = lockerCommand; }
        {
          timeout = 605;
          command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
          resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
        }
      ];
    };

  services.gammastep = {
    enable = true;
    provider = "geoclue2";
  };

  services.kanshi.enable = true;

  systemd.user.services.mako = {
    Unit = {
      Description = "Mako notification daemon";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.mako}/bin/mako";
      Restart = "always";
    };
    Install.WantedBy = [ "sway-session.target" ];
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
    Install.WantedBy = [ "sway-session.target" ];
  };

  systemd.user.services.yubikey-touch-detector = {
    Unit = {
      Description = "Yubikey Touch Detector";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify";
      Restart = "always";
    };
    Install.WantedBy = [ "sway-session.target" ];
  };

  xdg.configFile."sway/config".onChange = lib.mkForce "";
  wayland.windowManager.sway = {
    enable = true;
    config = {
      output."*".bg = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath} fill";
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
      menu = "${bemenuWithArgs}/bin/bemenu-run";
      terminal = "${pkgs.kitty}/bin/kitty";
      modifier = "Mod4";
      input =
        let
          keyboardSettings = { xkb_options = "ctrl:nocaps"; };
          touchpadSettings = {
            dwt = "enabled";
            natural_scroll = "enabled";
            tap = "enabled";
          };
        in
        {
          "type:keyboard" = keyboardSettings;
          "type:touchpad" = touchpadSettings;
          "113:16461:Logitech_K400_Plus" = keyboardSettings // touchpadSettings;
        };
      window = {
        hideEdgeBorders = "smart";
        titlebar = true;
      };
      defaultWorkspace = "workspace number 1";
      keybindings =
        let mod = config.wayland.windowManager.sway.config.modifier; in
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
          "${mod}+Control+space" = "${pkgs.mako}/bin/makoctl dismiss --all";
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
          "${mod}+c" = "exec ${pkgs.clipman}/bin/clipman pick --tool=CUSTOM --tool-args=${bemenuWithArgs}/bin/bemenu";
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
        mode = "hide";
        position = "bottom";
        statusCommand = "${pkgs.gobar}/bin/gobar";
        trayOutput = "*";
      }];
      workspaceAutoBackAndForth = true;
    };
  };
}
