{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.desktop;

  lockCmd = "${lib.getExe pkgs.swaylock} --daemonize --show-failed-attempts --color=000000";
in
{
  options.custom.desktop.enable = lib.mkEnableOption "desktop";

  config = lib.mkIf cfg.enable {
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
    services.printing.enable = true;
    services.automatic-timezoned.enable = true;

    services.greetd = {
      enable = true;
      settings.default_session.command = "${lib.getExe' pkgs.greetd.greetd "agreety"} --cmd labwc";
    };

    programs.labwc.enable = true;

    services.dbus.packages = [ pkgs.fnott ];

    environment.systemPackages = with pkgs; [
      alacritty
      brightnessctl
      cliphist
      fnott
      fuzzel
      openbox
      pamixer
      shotman
      vanilla-dmz
    ];

    environment.etc."xdg/fnott/fnott.ini".source =
      (pkgs.formats.iniWithGlobalSection { }).generate "fnott.ini"
        {
          globalSection = {
            background = "8cb0dcff"; # from clearlooks themerc
            max-timeout = 10;
            selection-helper = "fuzzel";
          };
        };

    environment.etc."xdg/labwc/autostart".text = ''
      systemctl --user start labwc-session.target
    '';

    environment.etc."xdg/labwc/environment".text = ''
      XCURSOR_SIZE=24
      XCURSOR_THEME=DMZ-Black
    '';

    programs.dconf = with lib.gvariant; {
      enable = true;
      profiles.user.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              cursor-size = mkInt32 24;
              cursor-theme = "DMZ-Black";
            };
          };
        }
      ];
    };

    environment.etc."xdg/labwc/rc.xml".source = pkgs.runCommand "labwc-rc.xml" { } ''
      ${lib.getExe pkgs.buildPackages.python3} ${./labwc-rc.py} > $out
    '';

    environment.etc."xdg/labwc/menu.xml".source = pkgs.runCommand "labwc-rc.xml" { } ''
      ${lib.getExe pkgs.buildPackages.python3} ${./labwc-menu.py} > $out
    '';

    systemd.user.targets.labwc-session = {
      description = "labwc compositor session";
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

    systemd.user.services.idle = {
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
        ExecStart = toString [
          (lib.getExe pkgs.swayidle)
          "-w"
          "timeout"
          "600"
          (lib.escapeShellArg "loginctl lock-session")
          "timeout"
          "1200"
          (lib.escapeShellArg "systemctl suspend")
          "before-sleep"
          (lib.escapeShellArg lockCmd)
          "lock"
          (lib.escapeShellArg lockCmd)
        ];
      };
    };

    systemd.user.services.clipboard = {
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

    systemd.user.services.nightlight = {
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
        ExecStart = "${lib.getExe pkgs.yubikey-touch-detector} --libnotify";
      };
    };
  };
}
