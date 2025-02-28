{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    gvariant
    mkDefault
    mkEnableOption
    mkIf
    optionals
    ;

  cfg = config.custom.desktop;

  backgroundColor = "1f3023";

  enabledExtensions = [
    pkgs.gnomeExtensions.appindicator
    pkgs.gnomeExtensions.caffeine
    pkgs.gnomeExtensions.clipboard-history
  ];

  setupFlathub = pkgs.writeShellApplication {
    name = "setup-flathub";
    text = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
  };
in
{
  options.custom.desktop.enable = mkEnableOption "desktop";

  config = mkIf cfg.enable {
    custom.normalUser.enable = true;
    custom.basicNetwork.enable = true;

    networking.wireless.iwd.enable = true;
    networking.networkmanager.wifi.backend = "iwd";

    services.flatpak.enable = mkDefault true;
    services.fwupd.enable = mkDefault true;
    services.printing.enable = mkDefault true;

    environment.systemPackages =
      [
        pkgs.ghostty
        pkgs.gnome-calculator
        pkgs.gnome-calendar
        pkgs.gnome-clocks
        pkgs.gnome-logs
        pkgs.gnome-text-editor
        pkgs.gnome-weather
        pkgs.loupe
        pkgs.nautilus
        pkgs.papers
        pkgs.snapshot
      ]
      ++ enabledExtensions
      ++ optionals config.services.flatpak.enable [
        setupFlathub
        pkgs.gnome-software
      ];

    programs.seahorse.enable = mkDefault true;
    programs.yubikey-touch-detector.enable = mkDefault true;

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

    # We use systemd-resolved
    services.avahi.enable = false;

    # It would be uncommon for a desktop system to have an NMEA serial device,
    # plus setting this to true means that geoclue will be dependent on avahi
    # being enabled, since NMEA support in geoclue uses avahi.
    services.geoclue2.enableNmea = mkDefault false;

    services.xserver.desktopManager.gnome.enable = true;
    services.xserver.displayManager.gdm.enable = true;

    services.gnome.core-utilities.enable = false;

    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings = {
            "org/gnome/desktop/wm/preferences".resize-with-right-button = gvariant.mkBoolean true;
            "org/gnome/system/location".enabled = gvariant.mkBoolean true;
            "org/gnome/desktop/datetime".automatic-timezone = gvariant.mkBoolean true;
            "org/gnome/mutter".experimental-features = gvariant.mkArray [
              "scale-monitor-framebuffer"
            ];
            "org/gnome/shell" = {
              enabled-extensions = gvariant.mkArray (map (extension: extension.extensionUuid) enabledExtensions);
              favorite-apps = gvariant.mkArray [
                "com.mitchellh.ghostty.desktop"
                "firefox.desktop"
              ];
            };
            "org/gnome/desktop/background" = {
              picture-uri = gvariant.mkString ""; # "file:///run/current-system/sw/share/backgrounds/gnome/vnc-l.png";
              picture-uri-dark = gvariant.mkString ""; # "file:///run/current-system/sw/share/backgrounds/gnome/vnc-d.png";
              primary-color = gvariant.mkString "#${backgroundColor}";
              secondary-color = gvariant.mkString "#${backgroundColor}";
            };
          };
        }
      ];
    };
  };
}
