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

  lockCmd = "${lib.getExe pkgs.swaylock} --daemonize --show-failed-attempts --color=222222";

  # For xwayland applications
  defaultIconTheme = pkgs.runCommand "default-icon-theme" { } ''
    mkdir -p $out/share/icons/default
    printf "[Icon Theme]\nInherits=${xcursorTheme}\n" >$out/share/icons/default/index.theme
  '';

  caffeineScript = pkgs.writeShellScriptBin "caffeine" ''
    time=''${1:-infinity}
    echo "inhibiting idle for $time"
    systemd-inhibit --what=idle --who=caffeine --why=Caffeine --mode=block sleep "$time"
  '';
in
{
  options.custom.desktop.enable = lib.mkEnableOption "desktop";

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [ "quiet" ];
    boot.consoleLogLevel = lib.mkDefault 3;

    custom.normalUser.enable = true;
    custom.basicNetwork.enable = true;

    networking.wireless.iwd.enable = true;
    networking.networkmanager.wifi.backend = "iwd";

    services.flatpak.enable = true;

    services.graphical-desktop.enable = true;

    services.greetd = {
      enable = true;
      settings.default_session.command = ''${lib.getExe' pkgs.greetd.greetd "agreety"} --cmd "systemd-cat --identifier=sway sway"'';
    };

    programs.sway = {
      enable = true;
      wrapperFeatures = {
        base = true;
        gtk = true;
      };
      extraPackages = [ ];
    };

    environment.systemPackages = [
      caffeineScript
      defaultIconTheme
      pkgs.alacritty
      pkgs.brightnessctl
      pkgs.clipman
      pkgs.desktop-file-utils
      pkgs.grim
      pkgs.libnotify
      pkgs.mako
      pkgs.swayidle
      pkgs.swaylock
      pkgs.tinybar
      pkgs.vanilla-dmz
      pkgs.wl-clipboard
      pkgs.wmenu
    ];

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

    programs.gnupg.agent.pinentryPackage = pkgs.wayprompt;

    systemd.user.services.clipman = {
      description = "Clipboard management daemon";
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --type text --watch ${lib.getExe pkgs.clipman} store";
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
              (lib.escapeShellArg "swaymsg 'output * power off'")
              "resume"
              (lib.escapeShellArg "swaymsg 'output * power on'")
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

    # Override the upstream defaults
    environment.etc."sway/config".source = lib.mkForce (
      pkgs.substituteAll {
        src = ./sway.conf.in;
        inherit xcursorSize xcursorTheme;
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
          general.import = [
            (pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/anhsirk0/alacritty-themes/97e2cf7151f7eaf61d0f9d973bdd9dc74e403f52/themes/modus-vivendi-deuteranopia.toml";
              hash = "sha256-6pc12Jy+B6i8dzauEOemy1Mipo/kHhSlVvX2HX9NsVU=";
            })
          ];
          general.live_config_reload = false;
          mouse.hide_when_typing = true;
          selection.save_to_clipboard = true;
          terminal.osc52 = "CopyPaste";
        };

    system.userActivationScripts.xdg-user-dirs = lib.getExe' pkgs.xdg-user-dirs "xdg-user-dirs-update";

    services.dbus.packages = [ pkgs.mako ];

    programs.yubikey-touch-detector.enable = true;

    services.fwupd.enable = lib.mkDefault true;

    hardware.bluetooth.enable = lib.mkDefault true;
    security.rtkit.enable = lib.mkDefault true;

    # We use systemd-resolved
    services.avahi.enable = false;

    services.automatic-timezoned.enable = lib.mkDefault true;
    services.upower.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault true;

    # It would be uncommon for a desktop system to have an NMEA serial device,
    # plus setting this to true means that geoclue will be dependent on avahi
    # being enabled, since NMEA support in geoclue uses avahi.
    services.geoclue2.enableNmea = lib.mkDefault false;
  };
}
