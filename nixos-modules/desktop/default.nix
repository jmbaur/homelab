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

    services.flatpak.enable = true;

    services.xserver = {
      enable = true;
      excludePackages = [ pkgs.xterm ];
      displayManager.gdm.enable = true;
      desktopManager.gnome = {
        enable = true;
        favoriteAppsOverride = ''
          [org.gnome.shell]
          favorite-apps=[ 'chromium-browser.desktop', 'org.gnome.Calendar.desktop', 'org.gnome.Nautilus.desktop' ]
        '';
      };
    };

    environment.gnome.excludePackages = [ pkgs.epiphany ];

    environment.systemPackages = [ pkgs.chromium ];

    networking.wireless.iwd.enable = true;
    networking.networkmanager.wifi.backend = "iwd";

    # TODO(jared): Doesn't cross compile
    services.fwupd.enable = pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform;

    hardware.bluetooth.enable = true;
    security.rtkit.enable = true;
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

    systemd.packages = [ pkgs.yubikey-touch-detector ];
    systemd.user.services.yubikey-touch-detector = {
      path = [ config.programs.gnupg.package ];
      wantedBy = [ "graphical-session.target" ];
    };
    systemd.user.services.yubikey-touch-detector.serviceConfig.ExecStart = [
      "" # clear previous ExecStart
      "${lib.getExe pkgs.yubikey-touch-detector} -libnotify"
    ];
  };
}
