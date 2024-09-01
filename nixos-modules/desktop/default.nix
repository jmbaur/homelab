{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.desktop;

  enabledGnomeExtensions = with pkgs.gnomeExtensions; [
    appindicator
    clipboard-indicator
    caffeine
  ];
in
{
  options.custom.desktop.enable = lib.mkEnableOption "desktop";

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [ "quiet" ];
    boot.consoleLogLevel = lib.mkDefault 3;

    custom.normalUser.enable = true;
    custom.basicNetwork.enable = true;

    environment.gnome.excludePackages = [ pkgs.gnome-console ];

    services.xserver = {
      enable = true;
      excludePackages = [ pkgs.xterm ];
      displayManager.gdm.enable = true;
      desktopManager.xterm.enable = false;
      desktopManager.gnome = {
        enable = true;
        favoriteAppsOverride = ''
          [org.gnome.shell]
          favorite-apps=[ 'firefox.desktop', 'org.gnome.Ptyxis.desktop', 'org.gnome.Nautilus.desktop' ]
        '';
      };
    };

    # Add a default browser to use
    programs.firefox = {
      enable = true;
      # Allow users to override preferences set here
      preferencesStatus = "user";
      # Default value only looks good in GNOME
      preferences."browser.tabs.inTitlebar" = lib.mkIf (
        !config.services.xserver.desktopManager.gnome.enable
      ) 0;
    };

    networking.wireless.iwd.enable = true;
    networking.networkmanager.wifi.backend = "iwd";

    # TODO(jared): Doesn't cross compile
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

    # We use systemd-resolved
    services.avahi.enable = false;

    # It would be uncommon for a desktop system to have an NMEA serial device,
    # plus setting this to true means that geoclue will be dependent on avahi
    # being enabled, since NMEA support in geoclue uses avahi.
    services.geoclue2.enableNmea = lib.mkDefault false;

    # MLS is deprecated: https://github.com/NixOS/nixpkgs/issues/321121
    #
    # NOTE: This is for personal usage only (and has very low limits), be a
    # good person and get your own API key.
    services.geoclue2.geoProviderUrl =
      "https://www.googleapis.com/geolocation/v1/geolocate?key="
      + "A"
      + "I"
      + "z"
      + "a"
      + "S"
      + "y"
      + "A"
      + "_"
      + "W"
      + "j"
      + "R"
      + "8"
      + "4"
      + "L"
      + "S"
      + "r"
      + "J"
      + "r"
      + "t"
      + "R"
      + "L"
      + "a"
      + "S"
      + "I"
      + "j"
      + "G"
      + "-"
      + "Q"
      + "f"
      + "n"
      + "s"
      + "c"
      + "N"
      + "c"
      + "v"
      + "3"
      + "P"
      + "y"
      + "Y";

    environment.systemPackages = enabledGnomeExtensions ++ [ pkgs.ptyxis ];

    systemd.packages = [ pkgs.yubikey-touch-detector ];
    systemd.user.services.yubikey-touch-detector = {
      path = [ config.programs.gnupg.package ];
      wantedBy = [ "graphical-session.target" ];
    };
    systemd.user.services.yubikey-touch-detector.serviceConfig.ExecStart = [
      "" # clear previous ExecStart
      "${lib.getExe pkgs.yubikey-touch-detector} -libnotify"
    ];

    programs.dconf = with lib.gvariant; {
      enable = true;
      profiles = with lib.gvariant; {
        user.databases = [
          {
            settings = {
              "org/gnome/desktop/peripherals/keyboard" = {
                repeat-interval = mkUint32 25;
                delay = mkUint32 300;
              };
              "org/gnome/desktop/background" = {
                picture-uri = mkString "file:///run/current-system/sw/share/backgrounds/gnome/vnc-l.png";
                picture-uri-dark = mkString "file:///run/current-system/sw/share/backgrounds/gnome/vnc-d.png";
              };
              "org/gnome/desktop/wm/preferences" = {
                resize-with-right-button = mkBoolean true;
              };
              "org/gnome/desktop/peripherals/touchpad" = {
                tap-to-click = mkBoolean true;
              };
              "org/gnome/desktop/input-sources" = {
                xkb-options = lib.splitString "," config.services.xserver.xkb.options;
              };
              "org/gnome/desktop/interface" = {
                clock-show-date = mkBoolean true;
                clock-show-weekday = mkBoolean true;
              };
              "org/gnome/shell".enabled-extensions = map (e: e.extensionUuid) enabledGnomeExtensions;
              "org/gnome/system/location".enabled = mkBoolean true;
              "org/gnome/desktop/datetime".automatic-timezone = mkBoolean true;
            };
          }
        ];
      };
    };
  };
}
