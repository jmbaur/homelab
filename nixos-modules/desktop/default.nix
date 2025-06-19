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

      environment.systemPackages = [
        pkgs.clipman
        pkgs.kanshi
        pkgs.mako
        pkgs.swayzbar
        pkgs.wl-clipboard
        (pkgs.runCommand "default-icon-theme" { } ''
          mkdir -p $out/share/icons
          ln -sf ${pkgs.adwaita-icon-theme}/share/icons/Adwaita $out/share/icons/default
        '')
      ];

      programs.yubikey-touch-detector.enable = mkDefault true;
      services.upower.enable = mkDefault true;
      services.fwupd.enable = mkDefault true;
      services.printing.enable = mkDefault true;
      services.automatic-timezoned.enable = mkDefault true;
      security.rtkit.enable = mkDefault true;

      environment.etc."sway/config".source = ./sway.config;

      environment.etc."sway/config.d/output.conf".text = ''
        exec kanshi --config ${pkgs.writeText "kanshi.conf" ''
          profile docked {
            output eDP-1 disable
            output * enable
          }
          profile undocked {
            output * enable
          }
        ''}
      '';

      programs.sway.enable = true;
      programs.foot = {
        enable = true;
        theme = "modus-vivendi";
        settings = {
          mouse.hide-when-typing = "yes";
          main = {
            font = "monospace:size=12";
            resize-by-cells = "no";
            selection-target = "both";
          };
        };
      };

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
              "browser.tabs.inTitlebar" = mkIf (!config.services.desktopManager.gnome.enable) 0;
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

      # Allows desktops to do stuff like timezone detection, display
      # modifications (brightness, redshift), etc.
      services.geoclue2.enable = true;

      # It would be uncommon for a desktop system to have an NMEA serial device,
      # plus setting this to true means that geoclue will be dependent on avahi
      # being enabled, since NMEA support in geoclue uses avahi.
      services.geoclue2.enableNmea = mkDefault false;
    }
  ]);
}
