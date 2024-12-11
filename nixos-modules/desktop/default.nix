{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.desktop;
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

    programs.labwc.enable = true;

    environment.etc."xdg/labwc".source = pkgs.runCommand "labwc-configs" { } ''
      mkdir -p $out
      ${lib.getExe pkgs.buildPackages.python3} ${./labwc-rc.py} >$out/rc.xml
      ${lib.getExe pkgs.buildPackages.python3} ${./labwc-menu.py} >$out/menu.xml
      printf "XCURSOR_SIZE=24\nXCURSOR_THEME=DMZ-Black\n" >$out/environment
      printf "systemctl --user start labwc-session.target\n" >$out/autostart
    '';

    services.dbus.packages = [ pkgs.fnott ];

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

    systemd.user.services.swayidle = {
      description = "Idle manager for Wayland";
      documentation = [ "man:swayidle(1)" ];
      unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];

      # swayidle executes commands using "sh -c", so the PATH needs to contain
      # a shell.
      path = [ pkgs.bash ];

      serviceConfig =
        let
          lockCmd = "${lib.getExe pkgs.swaylock} --daemonize --show-failed-attempts --color=000000";
        in
        {
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
        RestartSec = 3;
        Restart = "on-failure";
        ExecStart = toString [
          (lib.getExe pkgs.gammastep)
          "-l"
          "geoclue2"
        ];
      };
    };

    systemd.user.services.sfwbar = {
      description = "S* Floating Window Bar";
      documentation = [ "https://github.com/LBCrion/sfwbar" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        RestartSec = 3;
        Restart = "on-failure";
        ExecStart = lib.getExe pkgs.sfwbar;
      };
    };

    system.userActivationScripts.xdg-user-dirs = lib.getExe' pkgs.xdg-user-dirs "xdg-user-dirs-update";

    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              cursor-size = lib.gvariant.mkInt32 24;
              cursor-theme = "DMZ-Black";
            };
          };
        }
      ];
    };

    environment.systemPackages = [
      pkgs.alacritty
      pkgs.desktop-file-utils
      pkgs.openbox-menu
      pkgs.tinybar
      pkgs.vanilla-dmz
    ];

    services.greetd = {
      enable = true;
      settings.default_session.command = "${lib.getExe' pkgs.greetd.greetd "agreety"} --cmd \"systemd-cat --identifier=labwc labwc\"";
    };

    programs.yubikey-touch-detector.enable = true;

    services.fwupd.enable = lib.mkDefault true;

    hardware.bluetooth.enable = lib.mkDefault true;
    security.rtkit.enable = lib.mkDefault true;

    services.automatic-timezoned.enable = true;

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
