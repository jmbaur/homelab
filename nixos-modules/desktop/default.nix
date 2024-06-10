{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.desktop;

  xcursorSize = 24;
  xcursorTheme = "DMZ-Black";
  wallpaperPackage = pkgs.nixos-artwork.wallpapers.binary-white;
  wallpaperPath =
    let
      names = lib.splitString "/" wallpaperPackage.kdeFilePath;
    in
    "/"
    + lib.concatStringsSep "/" (
      [
        "run"
        "current-system"
        "sw"
      ]
      ++ lib.sublist 4 ((lib.length names) - 4) names
    );

  lockCmd = "${lib.getExe pkgs.swaylock} --daemonize --show-failed-attempts --image=${wallpaperPath} --scaling=fill";
in
{
  options.custom.desktop.enable = lib.mkEnableOption "desktop";

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [ "quiet" ];
    boot.consoleLogLevel = lib.mkDefault 3;

    custom.normalUser.enable = true;
    custom.basicNetwork.enable = true;

    # Add a default browser to use
    programs.firefox = {
      enable = true;
      # Allow users to override preferences set here
      preferencesStatus = "user";
      # Default value only looks good in GNOME
      preferences."browser.tabs.inTitlebar" = 0;
    };

    networking.wireless.iwd.enable = true;

    # Doesn't cross-compile
    services.fwupd.enable = pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform;

    hardware.bluetooth.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    services.pipewire.wireplumber.enable = true;
    services.printing.enable = lib.mkDefault true;
    services.automatic-timezoned.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault true;
    services.upower.enable = lib.mkDefault true;

    services.greetd = {
      enable = true;
      settings.default_session.command = "${lib.getExe' pkgs.greetd.greetd "agreety"} --cmd sway";
    };

    programs.sway = {
      enable = true;
      wrapperFeatures = {
        base = true;
        gtk = true;
      };
      extraPackages = [ ];
    };

    services.dbus.packages = [ pkgs.mako ];

    environment.pathsToLink = [ "/share/wallpapers" ];
    environment.systemPackages = with pkgs; [
      alacritty
      brightnessctl
      cliphist
      i3status # TODO(jared): remove this
      libnotify
      mako
      pamixer
      pulsemixer
      rofi-wayland
      shotman
      vanilla-dmz
      wallpaperPackage
      wl-clipboard
      (pkgs.writeShellScriptBin "caffeine" ''
        time=''${1:-infinity}
        echo "inhibiting idle for $time"
        systemd-inhibit --what=idle --who=caffeine --why=Caffeine --mode=block sleep "$time"
      '')
    ];

    system.userActivationScripts.xdg-user-dirs = lib.getExe' pkgs.xdg-user-dirs "xdg-user-dirs-update";

    # Same fonts as KDE, they're nice
    fonts.packages = [
      pkgs.noto-fonts
      pkgs.hack-font
    ];
    fonts.fontconfig.defaultFonts = {
      monospace = [
        "Hack"
        "Noto Sans Mono"
      ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };

    programs.gnupg.agent.pinentryPackage =
      # TODO(jared): Doesn't work, unknown reason.
      # pkgs.pinentry-rofi.override { rofi = pkgs.rofi-wayland; };
      pkgs.pinentry-tty;

    # Override the upstream defaults
    environment.etc."sway/config".source = lib.mkForce (
      pkgs.substituteAll {
        src = ./sway.conf.in;
        inherit xcursorSize xcursorTheme wallpaperPath;
        xkbLayout = config.services.xserver.xkb.layout;
        xkbModel = config.services.xserver.xkb.model;
        xkbOptions = config.services.xserver.xkb.options;
        xkbVariant = config.services.xserver.xkb.variant;

        postInstall = ''
          if grep --silent \/nix\/store $target; then
            echo "The default config should be able to be copied without any"
            echo "reliance on nix store paths, since these paths may not"
            echo "always exist (e.g. after garbage collection)."
            exit 1;
          fi
        '';
      }
    );

    environment.etc."xdg/alacritty/alacritty.toml".source =
      (pkgs.formats.toml { }).generate "alacritty.toml"
        {
          live_config_reload = false;
          mouse.hide_when_typing = true;
          selection.save_to_clipboard = true;
          font.size = 12;
          terminal.osc52 = "CopyPaste";
          import = [ "${pkgs.alacritty-theme}/xterm.toml" ];
        };

    programs.dconf = with lib.gvariant; {
      enable = true;
      profiles.user.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              cursor-size = mkInt32 xcursorSize;
              cursor-theme = xcursorTheme;
            };
          };
        }
      ];
    };

    systemd.user.targets.sway-session = {
      description = "Sway compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [
        "graphical-session-pre.target"
        "xdg-desktop-autostart.target"
      ];
      after = [
        "graphical-session-pre.target"
        "xdg-desktop-autostart.target"
      ];
    };

    systemd.user.services.swayidle = {
      description = "Idle manager for Wayland";
      documentation = [ "man:swayidle(1)" ];
      unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];

      # swayidle executes commands using "sh -c", so the PATH needs to contain
      # a shell.
      path = [ pkgs.bash ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = toString (
          lib.flatten [
            (lib.getExe pkgs.swayidle)
            "-w"
            [
              "timeout"
              "600"
              (lib.escapeShellArg "loginctl lock-session")
            ]
            [
              "timeout"
              "900"
              (lib.escapeShellArg "swaymsg output * power toggle")
              "resume"
              (lib.escapeShellArg "swaymsg output * power toggle")
            ]
            [
              "timeout"
              "1200"
              (lib.escapeShellArg "systemctl suspend")
            ]
            [
              "before-sleep"
              (lib.escapeShellArg lockCmd)
            ]
            [
              "lock"
              (lib.escapeShellArg lockCmd)
            ]
          ]
        );
      };
    };

    systemd.user.services.cliphist = {
      description = "Clipboard management daemon";
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --watch ${lib.getExe pkgs.cliphist} ${
          lib.escapeShellArgs [
            "-max-dedupe-search"
            "10"
            "-max-items"
            "500"
          ]
        } store";
        Restart = "on-failure";
      };
    };

    systemd.user.services.gammastep = {
      description = "Display colour temperature adjuster";
      documentation = [ "https://gitlab.com/chinstrap/gammastep" ];
      after = [
        "graphical-session-pre.target"
        config.systemd.user.services.geoclue-agent.name
      ];
      wants = [ config.systemd.user.services.geoclue-agent.name ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = toString [
          (lib.getExe pkgs.gammastep)
          "-l"
          "geoclue2"
        ];
        RestartSec = 3;
        Restart = "on-failure";
      };
    };

    systemd.user.services.yubikey-touch-detector = {
      description = "YubiKey touch notifier";
      documentation = [ "https://github.com/maximbaz/yubikey-touch-detector" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = toString [
          (lib.getExe pkgs.yubikey-touch-detector)
          "--libnotify"
        ];
      };
    };

    systemd.user.services.kanshi = {
      description = "Dynamic output configuration";
      documentation = [ "man:kanshi(1)" ];
      partOf = [ "graphical-session.target" ];
      requires = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      unitConfig.ConditionPathExists = "%h/.config/kanshi/config";
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = lib.getExe pkgs.kanshi;
      };
    };
  };
}
