{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    ;

  cfg = config.custom.desktop;
in
{
  options.custom.desktop.enable = mkEnableOption "desktop";

  config = mkIf cfg.enable (mkMerge [
    {
      custom.normalUser.enable = true;

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

      programs.yubikey-touch-detector.enable = mkDefault true;
      services.desktopManager.plasma6.enable = true;
      services.displayManager.sddm.enable = true;
      services.flatpak.enable = true;
      services.fwupd.enable = mkDefault true;
      services.printing.enable = mkDefault true;

      programs.dconf = {
        enable = true;
        profiles.user.databases = [ ];
      };

      programs.firefox = {
        enable = mkDefault true;

        # Allow users to override preferences set here
        preferencesStatus = "user";

        preferences = mkMerge (
          [
            {
              # Default value only looks good in GNOME
              "browser.tabs.inTitlebar" = mkIf (!config.services.xserver.desktopManager.gnome.enable) 0;
            }
          ]
          # Default is 2 for some reason, using 1 makes firefox use the
          # native portal variant.
          ++ map (opt: { "widget.use-xdg-desktop-portal.${opt}" = 1; }) [
            "file-picker"
            "mime-handler"
            "settings"
            "location"
            "open-uri"
          ]
        );
      };
    }

    # Networking defaults
    {
      custom.basicNetwork.enable = true;

      networking.wireless.iwd.enable = true;
      networking.networkmanager.wifi.backend = "iwd";

      # plasma6 does not enable this by default
      networking.networkmanager.enable = mkIf config.services.desktopManager.plasma6.enable (
        mkDefault true
      );

      hardware.bluetooth.enable = true;

      # We use systemd-resolved
      services.avahi.enable = false;

      # It would be uncommon for a desktop system to have an NMEA serial device,
      # plus setting this to true means that geoclue will be dependent on avahi
      # being enabled, since NMEA support in geoclue uses avahi.
      services.geoclue2.enableNmea = mkDefault false;
    }
  ]);
}
