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
        pkgs.i3status
        pkgs.kanshi
        pkgs.mako
        pkgs.wl-clipboard
        (pkgs.runCommand "default-icon-theme" { } ''
          mkdir -p $out/share/icons
          ln -sf ${pkgs.adwaita-icon-theme}/share/icons/Adwaita $out/share/icons/default
        '')
      ];

      programs.yubikey-touch-detector.enable = mkDefault true;
      services.fwupd.enable = mkDefault true;
      services.printing.enable = mkDefault true;
      services.automatic-timezoned.enable = mkDefault true;
      security.rtkit.enable = mkDefault true;

      environment.etc."sway/config.d/input.conf".text = ''
        input type:keyboard xkb_options ctrl:nocaps
        input type:touchpad {
          natural_scroll enabled
          tap enabled
        }
      '';

      environment.etc."sway/config.d/idle.conf".text = ''
        exec swayidle -w timeout 300 'swaylock -f -c 000000' timeout 600 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"' before-sleep 'swaylock -f -c 000000' lock 'swaylock -f -c 000000'
      '';

      environment.etc."sway/config.d/output.conf".text = ''
        output * background #444444 solid_color
      '';

      environment.etc."sway/config.d/custom.conf".text = ''
        bindsym $mod+Shift+d exec makoctl dismiss --all
        bindsym $mod+Shift+v exec clipman pick --tool CUSTOM --tool-args wmenu --err-on-no-selection
        bindsym $mod+Shift+s sticky toggle
        bindsym $mod+Control+l exec loginctl lock-session

        exec wl-paste -t text --watch clipman store

        workspace_auto_back_and_forth yes

        bar {
          position top
          binding_mode_indicator no
          workspace_buttons no
          mode hide
          tray_output none
          status_command i3status
          colors {
            statusline #ffffff
            background #323232
            inactive_workspace #32323200 #32323200 #5c5c5c
          }
        }
      '';

      programs.sway.enable = true;
      programs.foot = {
        enable = true;
        settings = {
          mouse.hide-when-typing = "yes";
          main = {
            selection-target = "both";
            font = "monospace:size=12";
          };
          colors = {
            background = "000000";
            foreground = "ffffff";
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
