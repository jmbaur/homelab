{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    ;

  cfg = config.custom.desktop;
in
{
  options.custom.desktop.enable = mkEnableOption "desktop";

  config = mkIf cfg.enable {
    boot.kernelParams = [ "quiet" ];
    boot.consoleLogLevel = mkDefault 3;

    custom.normalUser.enable = true;
    custom.basicNetwork.enable = true;

    networking.wireless.iwd.enable = true;
    networking.networkmanager = {
      # plasma6 does not enable this by default
      enable = mkIf config.services.desktopManager.plasma6.enable (mkDefault true);
      wifi.backend = "iwd";
    };

    services.flatpak.enable = true;

    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm.enable = true;

    programs.yubikey-touch-detector.enable = mkDefault true;

    services.fwupd.enable = mkDefault true;

    services.printing.enable = mkDefault true;

    hardware.bluetooth.enable = mkDefault true;
    security.rtkit.enable = mkDefault true;

    # We use systemd-resolved
    services.avahi.enable = false;

    # It would be uncommon for a desktop system to have an NMEA serial device,
    # plus setting this to true means that geoclue will be dependent on avahi
    # being enabled, since NMEA support in geoclue uses avahi.
    services.geoclue2.enableNmea = mkDefault false;
  };
}
