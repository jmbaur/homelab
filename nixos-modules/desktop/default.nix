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

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    services.desktopManager.plasma6.enable = true;

    environment.plasma6.excludePackages = [ pkgs.kdePackages.kate ];

    programs.yubikey-touch-detector.enable = true;

    programs.firefox = {
      enable = true;
      # Allow users to override preferences set here
      preferencesStatus = "user";
      # Default value only looks good in GNOME
      preferences."browser.tabs.inTitlebar" = lib.mkIf (
        !config.services.xserver.desktopManager.gnome.enable
      ) 0;
      policies = {
        DisablePocket = true;
        FirefoxHome = {
          TopSites = false;
          SponsoredTopSites = false;
          SponsoredPocket = false;
        };
      };
    };

    networking.wireless.iwd.enable = true;
    networking.networkmanager = {
      enable = lib.mkDefault true;
      wifi.backend = "iwd";
    };

    # TODO(jared): Doesn't cross compile
    services.fwupd.enable = pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform;

    hardware.bluetooth.enable = lib.mkDefault true;
    security.rtkit.enable = lib.mkDefault true;
    services.pipewire.wireplumber.enable = lib.mkDefault true;

    # We use systemd-resolved
    services.avahi.enable = false;

    # It would be uncommon for a desktop system to have an NMEA serial device,
    # plus setting this to true means that geoclue will be dependent on avahi
    # being enabled, since NMEA support in geoclue uses avahi.
    services.geoclue2.enableNmea = lib.mkDefault false;
  };
}
