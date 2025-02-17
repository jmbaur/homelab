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

    services.flatpak.enable = true;
    services.fwupd.enable = mkDefault true;

    fonts.packages = [ pkgs.commit-mono ];
    fonts.fontconfig.defaultFonts.monospace = [ "CommitMono" ];

    environment.systemPackages = [
      pkgs.ghostty
      pkgs.gnomeExtensions.appindicator
      pkgs.gnomeExtensions.caffeine
      pkgs.gnomeExtensions.clipboard-history
    ] ++ optionals config.services.flatpak.enable [ setupFlathub ];

    programs.yubikey-touch-detector.enable = true;

    # Add a default browser to use
    programs.firefox = {
      enable = true;
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
            "org/gnome/desktop/wm/preferences" = {
              resize-with-right-button = gvariant.mkBoolean true;
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
