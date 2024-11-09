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

    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome = {
        enable = true;
        sessionPath = with pkgs.gnomeExtensions; [
          appindicator
          clipboard-history
        ];
      };
      excludePackages = [ pkgs.xterm ];
    };

    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings."org/gnome/desktop/wm/preferences".resize-with-right-button = lib.gvariant.mkBoolean true;
        }
      ];
    };

    environment.systemPackages = [ pkgs.desktop-file-utils ];

    programs.yubikey-touch-detector.enable = true;

    services.fwupd.enable = lib.mkDefault true;

    hardware.bluetooth.enable = lib.mkDefault true;
    security.rtkit.enable = lib.mkDefault true;

    # We use systemd-resolved
    services.avahi.enable = false;

    # It would be uncommon for a desktop system to have an NMEA serial device,
    # plus setting this to true means that geoclue will be dependent on avahi
    # being enabled, since NMEA support in geoclue uses avahi.
    services.geoclue2.enableNmea = lib.mkDefault false;
  };
}
