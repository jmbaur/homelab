{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    escapeShellArg
    flatten
    getExe
    getExe'
    mkDefault
    mkEnableOption
    mkForce
    mkIf
    mkMerge
    ;

  cfg = config.custom.desktop;

  lockCmd = toString [
    (getExe pkgs.swaylock)
    "--daemonize"
    "--show-failed-attempts"
    "--indicator-caps-lock"
    "--image=/etc/sway/wallpaper"
    "--scaling fill"
  ];
in
{
  options.custom.desktop.enable = mkEnableOption "desktop";

  config = mkIf cfg.enable (mkMerge [
    {
      custom.normalUser.enable = true;

      services.fwupd.enable = mkDefault true;

      services.evremap = {
        enable = mkDefault true;
        settings.device_name = mkIf pkgs.stdenv.hostPlatform.isx86_64 (
          mkDefault "AT Translated Set 2 keyboard"
        );

        settings.remap = mkDefault [
          {
            input = [ "KEY_CAPSLOCK" ];
            output = [ "KEY_LEFTCTRL" ];
          }
          {
            input = [ "KEY_LEFTCTRL" ];
            output = [ "KEY_CAPSLOCK" ];
          }
        ];
      };

      services.automatic-timezoned.enable = mkDefault true;

      programs.yubikey-touch-detector.enable = mkDefault true;

      system.userActivationScripts.xdg-user-dirs = getExe' pkgs.xdg-user-dirs "xdg-user-dirs-update";

      programs.dconf = {
        enable = true;
        profiles.user.databases = [ ];
      };

      # Add a default browser to use
      programs.firefox = {
        enable = mkDefault true;
        # Allow users to override preferences set here
        preferencesStatus = "user";
        # Default value only looks good in GNOME
        preferences."browser.tabs.inTitlebar" = mkIf (
          !config.services.xserver.desktopManager.gnome.enable
        ) 0;
      };
    }

    # Networking defaults
    {
      custom.basicNetwork.enable = true;

      networking.wireless.iwd.enable = true;
      networking.networkmanager.wifi.backend = "iwd";

      hardware.bluetooth.enable = true;

      # We use systemd-resolved
      services.avahi.enable = false;

      # It would be uncommon for a desktop system to have an NMEA serial device,
      # plus setting this to true means that geoclue will be dependent on avahi
      # being enabled, since NMEA support in geoclue uses avahi.
      services.geoclue2.enableNmea = mkDefault false;
    }

    # Display brightness
    {
      # TODO(jared): Find or write a utility that can modify brightness of
      # internal and external displays at once.
      environment.systemPackages = [
        pkgs.brightnessctl
        pkgs.ddcutil
      ];

      boot.kernelModules = [ "i2c-dev" ];

      # The usual case, using TAG+="uaccess":  If a /dev/i2c device is associated
      # with a video adapter, grant the current user access to it.
      services.udev.extraRules = ''
        SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", ATTRS{class}=="0x030000", TAG+="uaccess"
      '';
    }

    {
      programs.sway = {
        enable = true;
        wrapperFeatures = {
          base = true;
          gtk = true;
        };
        extraPackages = [ ];
      };

      environment.loginShellInit = ''
        if [ -z "$WAYLAND_DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ] ; then
            exec systemd-cat --identifier=sway sway
        fi
      '';

      fonts.packages = [ pkgs.jetbrains-mono ];
      fonts.fontconfig.defaultFonts.monospace = [ "JetBrainsMono" ];

      systemd.packages = [ pkgs.mako ];
      services.dbus.packages = [ pkgs.mako ];

      environment.etc."xdg/rofi.rasi".text = ''
        @theme "Paper"
      '';

      environment.etc."xdg/foot/foot.ini".source =
        (pkgs.formats.ini { listsAsDuplicateKeys = true; }).generate "foot.ini"
          {
            main.include = [
              (pkgs.concatText "foot-paper-color-light.ini" [ "${pkgs.foot.src}/themes/paper-color-light" ])
            ];
            main.font = "monospace:size=12"; # default font is far too small
            main.pad = "4x4";
            main.resize-by-cells = false; # TODO(jared): sway issue, documented here: https://codeberg.org/dnkl/foot/issues/1675#issuecomment-1736249
            main.selection-target = "both";
            mouse.hide-when-typing = "yes";
          };

      environment.etc."sway/config".source = mkForce ./sway.config;

      systemd.tmpfiles.settings."10-sway-wallpaper"."/etc/sway/wallpaper".C = {
        mode = "0666";
        argument = "${pkgs.sway-unwrapped}/share/backgrounds/sway/Sway_Wallpaper_Blue_1920x1080.png";
      };

      programs.gnupg.agent.pinentryPackage = pkgs.pinentry-rofi.override {
        rofi = pkgs.rofi-wayland;
      };

      environment.systemPackages = [
        pkgs.brightnessctl
        pkgs.clipman
        pkgs.foot
        pkgs.grim
        pkgs.libnotify
        pkgs.mako
        pkgs.rofi-wayland
        pkgs.swayidle
        pkgs.swaylock
        pkgs.swayzbar
        pkgs.wl-mirror
        pkgs.wlay
        (pkgs.symlinkJoin {
          name = "default-${pkgs.xcursor-chromeos.name}";
          paths = [ pkgs.xcursor-chromeos ];
          postBuild = ''
            ln -sf $out/share/icons/${pkgs.xcursor-chromeos.pname} $out/share/icons/default
          '';
        })
      ];

      # Example config:
      #
      # profile docked {
      #   output eDP-1 disable
      #   output * enable
      # }
      # profile undocked {
      #   output * enable
      # }
      systemd.user.services.kanshi = {
        description = "Dynamic display management";
        documentation = [ "man:kanshi(1)" ];
        unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
        unitConfig.ConditionPathExists = "%h/.config/kanshi/config"; # crashes without this file
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 3;
          ExecStart = getExe pkgs.kanshi;
        };
      };

      systemd.user.services.clipman = {
        description = "Clipboard management daemon";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 3;
          ExecStart = "${getExe' pkgs.wl-clipboard "wl-paste"} --type text --watch ${getExe pkgs.clipman} store";
        };
      };

      systemd.user.services.swayidle = {
        description = "Idle manager for Wayland";
        documentation = [ "man:swayidle(1)" ];
        unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        # swayidle executes commands using "sh -c", so the PATH needs to contain
        # a shell.
        path = [ pkgs.bash ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 3;
          ExecStart = toString (
            flatten (
              [
                (getExe pkgs.swayidle)
                "-w"
                [
                  "timeout"
                  "600"
                  (escapeShellArg "loginctl lock-session")
                ]
                [
                  "timeout"
                  "900"
                  (escapeShellArg "swaymsg 'output * power off'")
                  "resume"
                  (escapeShellArg "swaymsg 'output * power on'")
                ]
              ]
              ++ lib.optionals (!config.custom.server.enable) ([
                [
                  "timeout"
                  "1200"
                  (escapeShellArg "systemctl suspend")
                ]
              ])
              ++ [
                [
                  "before-sleep"
                  (escapeShellArg lockCmd)
                ]
                [
                  "lock"
                  (escapeShellArg lockCmd)
                ]
              ]
            )
          );
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
          Restart = "on-failure";
          RestartSec = 3;
          ExecStart = toString [
            (getExe pkgs.gammastep)
            "-l"
            "geoclue2"
          ];
        };
      };
    }
  ]);
}
