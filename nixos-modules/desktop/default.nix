{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.desktop;

  xcursorSize = 24;
  xcursorTheme = "Adwaita";

  backgroundColor = "1f3023";

  lockCmd = "${lib.getExe pkgs.swaylock} --daemonize --show-failed-attempts --color=${backgroundColor}";

  # For xwayland applications
  defaultIconTheme = pkgs.runCommand "default-icon-theme" { } ''
    mkdir -p $out/share/icons/default
    printf "[Icon Theme]\nInherits=${xcursorTheme}\n" >$out/share/icons/default/index.theme
  '';

  setupFlathub = pkgs.writeShellApplication {
    name = "setup-flathub";
    text = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
  };
in
{
  options.custom.desktop.enable = lib.mkEnableOption "desktop";

  config = lib.mkIf cfg.enable {
    custom.normalUser.enable = true;
    custom.basicNetwork.enable = true;

    networking.wireless.iwd.enable = true;
    networking.networkmanager.wifi.backend = "iwd";

    services.flatpak.enable = true;

    programs.sway = {
      enable = true;
      wrapperFeatures = {
        base = true;
        gtk = true;
      };
      extraPackages = [ ];
    };

    # Override the upstream defaults
    environment.etc."sway/config".source = lib.mkForce (
      pkgs.substituteAll {
        name = "sway.conf";
        src = ./sway.conf.in;
        inherit xcursorSize xcursorTheme backgroundColor;
        xkbLayout = config.services.xserver.xkb.layout;
        xkbModel = config.services.xserver.xkb.model;
        xkbOptions = config.services.xserver.xkb.options;
        xkbVariant = config.services.xserver.xkb.variant;

        postInstall = ''
          if grep --silent ${lib.escape [ "/" ] builtins.storeDir} $target; then
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
            (pkgs.runCommand "gruvbox_dark.toml" { } "cat ${pkgs.alacritty-theme}/gruvbox_dark.toml >$out")
          ];
          font.size = 12.0;
          general.live_config_reload = false;
          mouse.hide_when_typing = true;
          selection.save_to_clipboard = true;
        };

    environment.etc."xdg/rofi.rasi".source = ./rofi.rasi;

    fonts.packages = [ pkgs.monaspace ];
    fonts.fontconfig.defaultFonts.monospace = [ "Monaspace Neon" ];

    systemd.packages = [ pkgs.mako ];
    systemd.user.services.mako.environment.XDG_CONFIG_HOME = pkgs.writeTextDir "mako/config" ''
      default-timeout=${
        toString (10 * 1000) # milliseconds
      }
    '';

    # Make pinentry-rofi work with gpg-agent, remove if/when
    # https://github.com/NixOS/nixpkgs/pull/366240 is merged.
    systemd.user.services.gpg-agent.path = [ pkgs.rofi-wayland ];

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

    systemd.user.services.clipman = {
      description = "Clipboard management daemon";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 3;
        ExecStart = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --type text --watch ${lib.getExe pkgs.clipman} store";
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
          (lib.getExe pkgs.gammastep)
          "-l"
          "geoclue2"
        ];
      };
    };

    systemd.user.services.kanshi = {
      description = "Dynamic display management";
      documentation = [ "man:kanshi(1)" ];
      unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      environment.XDG_CONFIG_HOME = pkgs.writeTextDir "kanshi/config" ''
        profile docked {
          output eDP-1 disable
          output * enable
        }

        profile undocked {
          output * enable
        }
      '';
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 3;
        ExecStart = lib.getExe pkgs.kanshi;
      };
    };

    system.userActivationScripts.xdg-user-dirs = lib.getExe' pkgs.xdg-user-dirs "xdg-user-dirs-update";

    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              cursor-size = lib.gvariant.mkInt32 xcursorSize;
              cursor-theme = xcursorTheme;
              gtk-theme = "Adwaita-dark";
            };
          };
        }
      ];
    };

    programs.gnupg.agent.pinentryPackage = pkgs.pinentry-rofi.override {
      rofi = pkgs.rofi-wayland;
    };

    environment.systemPackages = [
      defaultIconTheme
      pkgs.alacritty
      pkgs.brightnessctl
      pkgs.clipman
      pkgs.desktop-file-utils
      pkgs.gnome-themes-extra
      pkgs.grim
      pkgs.kanshi
      pkgs.libnotify
      pkgs.mako
      pkgs.rofi-wayland
      pkgs.swayidle
      pkgs.swaylock
      pkgs.tinybar
      pkgs.wl-clipboard
    ] ++ lib.optionals config.services.flatpak.enable [ setupFlathub ];

    programs.uwsm = {
      enable = true;
      waylandCompositors = { };
    };

    services.greetd = {
      enable = true;
      settings.default_session.command = "${lib.getExe' pkgs.greetd.greetd "agreety"} --cmd \"systemd-cat --identifier=uwsm-sway uwsm start -S -F /run/current-system/sw/bin/sway\"";
    };

    programs.yubikey-touch-detector.enable = true;

    services.fwupd.enable = lib.mkDefault true;

    hardware.bluetooth.enable = lib.mkDefault true;
    security.rtkit.enable = lib.mkDefault true;

    services.automatic-timezoned.enable = true;
    services.upower.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault true;

    # Add a default browser to use
    programs.firefox = {
      enable = true;
      # Allow users to override preferences set here
      preferencesStatus = "user";
      # Default value only looks good in GNOME
      preferences."browser.tabs.inTitlebar" = 0;
    };

    # We use systemd-resolved
    services.avahi.enable = false;

    # It would be uncommon for a desktop system to have an NMEA serial device,
    # plus setting this to true means that geoclue will be dependent on avahi
    # being enabled, since NMEA support in geoclue uses avahi.
    services.geoclue2.enableNmea = lib.mkDefault false;
  };
}
