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
    gvariant
    mkMerge
    ;

  cfg = config.custom.desktop;

  enabledExtensions = [
    pkgs.gnomeExtensions.appindicator
    pkgs.gnomeExtensions.caffeine
    pkgs.gnomeExtensions.clipboard-history
  ];
in
{
  options.custom.desktop.enable = mkEnableOption "desktop";

  config = mkIf cfg.enable (mkMerge [
    {
      boot.kernelParams = [ "quiet" ];

      custom.normalUser.enable = true;

      services.flatpak.enable = mkDefault true;
      services.fwupd.enable = mkDefault true;
      services.printing.enable = mkDefault true;

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

      services.xserver = {
        enable = true;
        excludePackages = [ pkgs.xterm ];
        desktopManager.gnome.enable = true;
        displayManager.gdm.enable = true;
      };

      environment.systemPackages = enabledExtensions;

      programs.dconf = {
        enable = true;
        profiles.user.databases = [
          {
            settings = {
              "org/gnome/desktop/wm/preferences".resize-with-right-button = gvariant.mkBoolean true;
              "org/gnome/system/location".enabled = gvariant.mkBoolean true;
              "org/gnome/desktop/datetime".automatic-timezone = gvariant.mkBoolean true;
              "org/gnome/mutter".experimental-features = gvariant.mkArray [ "scale-monitor-framebuffer" ];
              "org/gnome/shell" = {
                enabled-extensions = gvariant.mkArray (map (extension: extension.extensionUuid) enabledExtensions);
                favorite-apps = gvariant.mkArray [
                  "firefox.desktop"
                  "org.gnome.Console.desktop"
                  "org.gnome.Nautilus.desktop"
                  "org.gnome.Settings.desktop"
                ];
              };
              "org/gnome/desktop/background" = {
                picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/vnc-l.png";
                picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/vnc-d.png";
              };
            };
          }
        ];
      };

      systemd.services.setup-flathub = mkIf config.services.flatpak.enable {
        unitConfig.ConditionPathExists = "!/var/lib/flatpak/repo/flathub.trustedkeys.gpg";
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Restart = "on-failure";
        serviceConfig.ExecStart = "${lib.getExe config.services.flatpak.package} remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo";
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

      # We use systemd-resolved
      services.avahi.enable = false;

      # It would be uncommon for a desktop system to have an NMEA serial device,
      # plus setting this to true means that geoclue will be dependent on avahi
      # being enabled, since NMEA support in geoclue uses avahi.
      services.geoclue2.enableNmea = mkDefault false;
    }
  ]);
}
