{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    getExe
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

      services.greetd = {
        enable = true;
        settings.default_session.command = toString [
          (getExe config.programs.labwc.package)
          "--config-dir"
          (pkgs.runCommand "labwc-greetd-config-dir" { } ''
            mkdir -p $out
            install -Dm0644 ${./labwc-greetd-rc.xml} $out/rc.xml
            echo '${config.systemd.user.services.swaybg.serviceConfig.ExecStart} &' >$out/autostart
            chmod +x $out/autostart
          '')
          "--session"
          "'${getExe pkgs.wlgreet} --command \"systemd-cat --identifier=labwc ${getExe config.programs.labwc.package} --merge-config --session=${getExe pkgs.sfwbar}\"'"
        ];
      };

      programs.labwc.enable = true;

      systemd.user.targets.labwc-session = {
        description = "labwc session";
        documentation = [ "man:labwc(1) man:systemd.special(7)" ];
        bindsTo = [ "graphical-session.target" ];
        wants = [ "graphical-session-pre.target" ];
        after = [ "graphical-session-pre.target" ];
      };

      systemd.user.services.swaybg = {
        serviceConfig.ExecStart = toString [
          (getExe pkgs.swaybg)
          "--mode"
          "tile"
          "--image"
          (pkgs.runCommand "weston-pattern.png" { } ''
            install -Dm0644 ${pkgs.weston}/share/weston/pattern.png $out
          '')
        ];
        wantedBy = [ "graphical-session.target" ];
      };

      systemd.user.services.swayidle = {
        serviceConfig.ExecStart = toString [
          (getExe pkgs.swayidle)
          "-w"
          "timeout"
          300
          "'swaylock -f'"
          "timeout"
          600
          "'wlopm --off *'"
          "before-sleep"
          "'swaylock -f'"
        ];
        wantedBy = [ "graphical-session.target" ];
      };

      environment.etc."xdg/foot/foot.ini".source = (pkgs.formats.ini { }).generate "foot.ini" {
        main.font = "monospace:size=10";
      };

      environment.etc."xdg/labwc/autostart".source = pkgs.writeShellScript "labwc-autostart" ''
        systemctl --user import-environment ${
          toString [
            "DISPLAY"
            "WAYLAND_DISPLAY"
            "XDG_CURRENT_DESKTOP"
            "XDG_SESSION_TYPE"
            "NIXOS_OZONE_WL"
            "XCURSOR_THEME"
            "XCURSOR_SIZE"
          ]
        }
        systemctl --user --no-block start labwc-session.target
      '';

      environment.etc."xdg/labwc/shutdown".source = pkgs.writeShellScript "labwc-shutdown" ''
        systemctl --user --no-block stop labwc-session.target
      '';

      environment.etc."xdg/labwc/environment".source =
        (pkgs.formats.keyValue { }).generate "labwc-environment"
          {
            XKB_DEFAULT_MODEL = config.services.xserver.xkb.model;
            XKB_DEFAULT_OPTIONS = config.services.xserver.xkb.options;
            XKB_DEFAULT_VARIANT = config.services.xserver.xkb.variant;
          };

      environment.etc."xdg/labwc/rc.xml".source = ./labwc-rc.xml;

      environment.systemPackages = [
        pkgs.brightnessctl
        pkgs.foot
        pkgs.grim
        pkgs.labwc-tweaks
        pkgs.sfwbar
        pkgs.slurp
        pkgs.swaybg
        pkgs.swayidle
        pkgs.swaylock
        pkgs.wlopm
        (pkgs.symlinkJoin {
          name = "default-${pkgs.xcursor-chromeos.name}";
          paths = [ pkgs.xcursor-chromeos ];
          postBuild = ''
            ln -sf $out/share/icons/${pkgs.xcursor-chromeos.pname} $out/share/icons/default
          '';
        })
      ];

      programs.yubikey-touch-detector.enable = mkDefault true;
      security.rtkit.enable = mkDefault true;
      services.fwupd.enable = mkDefault true;
      services.printing.enable = mkDefault true;
      services.upower.enable = mkDefault true;

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

      networking.wireless.iwd.enable = mkDefault true;
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
