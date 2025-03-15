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
    optionals
    ;

  cfg = config.custom.desktop;

  setupFlathub = pkgs.writeShellApplication {
    name = "setup-flathub";
    text = "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo";
  };
in
{
  options.custom.desktop.enable = mkEnableOption "desktop";

  config = mkIf cfg.enable (mkMerge [
    {
      custom.normalUser.enable = true;

      services.automatic-timezoned.enable = mkDefault true;
      services.dbus.packages = [ pkgs.mako ];
      services.flatpak.enable = mkDefault true;
      services.fwupd.enable = mkDefault true;
      services.power-profiles-daemon.enable = mkDefault true;
      services.printing.enable = mkDefault true;
      services.upower.enable = mkDefault true;

      programs.sway = {
        enable = true;
        wrapperFeatures = {
          base = true;
          gtk = true;
        };
      };

      services.evremap = {
        enable = true;
        settings.device_name = mkDefault "AT Translated Set 2 keyboard";

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

      systemd.packages = [ pkgs.mako ];

      # TODO(jared): sway issue, documented here: https://codeberg.org/dnkl/foot/issues/1675#issuecomment-1736249
      environment.etc."xdg/foot/foot.ini".source = (pkgs.formats.ini { }).generate "foot.ini" {
        main.resize-by-cells = false;
      };

      environment.systemPackages =
        [
          pkgs.mako
          (pkgs.symlinkJoin {
            name = "default-${pkgs.xcursor-chromeos.name}";
            paths = [ pkgs.xcursor-chromeos ];
            postBuild = ''
              ln -sf $out/share/icons/${pkgs.xcursor-chromeos.pname} $out/share/icons/default
            '';
          })
        ]
        ++ optionals config.services.flatpak.enable [ setupFlathub ]
        ++ optionals config.programs.firefox.enable [ pkgs.firefoxpwa ];

      # Add a default browser to use
      programs.firefox = {
        enable = mkDefault true;
        # Allow users to override preferences set here
        preferencesStatus = "user";
        # Default value only looks good in GNOME
        preferences."browser.tabs.inTitlebar" = mkIf (
          !config.services.xserver.desktopManager.gnome.enable
        ) 0;
        # Make it possible for firefox to be the only desktop app.
        nativeMessagingHosts.packages = [ pkgs.firefoxpwa ];
      };
    }

    # Networking defaults
    {
      custom.basicNetwork.enable = true;

      networking.wireless.iwd.enable = true;
      networking.networkmanager.wifi.backend = "iwd";

      hardware.bluetooth.enable = true;

      # We use systemd-resolved
      services.avahi.enable = false;

      # It would be uncommon for a desktop system to have an NMEA serial device,
      # plus setting this to true means that geoclue will be dependent on avahi
      # being enabled, since NMEA support in geoclue uses avahi.
      services.geoclue2.enableNmea = mkDefault false;
    }

    # Display brightness
    {
      # TODO(jared): Find or write a utility that can modify brightness of
      # internal and external displays at once.
      environment.systemPackages = [
        pkgs.brightnessctl
        pkgs.ddcutil
      ];

      boot.kernelModules = [ "i2c-dev" ];

      # The usual case, using TAG+="uaccess":  If a /dev/i2c device is associated
      # with a video adapter, grant the current user access to it.
      services.udev.extraRules = ''
        SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", ATTRS{class}=="0x030000", TAG+="uaccess"
      '';
    }
  ]);
}
