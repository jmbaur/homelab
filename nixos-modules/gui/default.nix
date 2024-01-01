{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;

  enabledGnomeExtensions = with pkgs.gnomeExtensions; [ appindicator clipboard-indicator caffeine ];
in
{
  options.custom.gui = with lib; {
    enable = mkEnableOption "GUI config";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    programs.gnupg.agent.enable = true;
    programs.ssh.startAgent = true;

    # ensure the plugdev group exists for udev rules for qmk
    users.groups.plugdev = { };
    services.udev.packages = [
      pkgs.yubikey-personalization
      pkgs.qmk-udev-rules
      pkgs.teensy-udev-rules
    ];

    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [ "teensy-udev-rules" ];

    hardware.pulseaudio.enable = lib.mkForce false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # needed by some apps
    environment.sessionVariables.XCURSOR_SIZE = "32";

    environment.systemPackages = enabledGnomeExtensions;

    programs.dconf = {
      enable = true;
      profiles = with lib.gvariant; {
        gdm.databases = [{
          settings = {
            "org/gnome/desktop/interface" = {
              color-scheme = mkString "prefer-light";
              cursor-size = mkInt32 32;
            };
          };
        }];
        user.databases = [{
          settings = {
            "org/gnome/desktop/peripherals/keyboard" = {
              repeat-interval = mkUint32 25;
              delay = mkUint32 300;
            };
            "org/gnome/desktop/background" = {
              picture-uri = mkString "file:///run/current-system/sw/share/backgrounds/gnome/vnc-l.png";
              picture-uri-dark = mkString "file:///run/current-system/sw/share/backgrounds/gnome/vnc-d.png";
            };
            "org/gnome/desktop/wm/preferences" = {
              resize-with-right-button = mkBoolean true;
            };
            "org/gnome/desktop/peripherals/touchpad" = {
              tap-to-click = mkBoolean true;
            };
            "org/gnome/desktop/input-sources" = {
              xkb-options = lib.splitString "," config.services.xserver.xkb.options;
            };
            "org/gnome/desktop/interface" = {
              clock-show-date = mkBoolean true;
              clock-show-weekday = mkBoolean true;
              color-scheme = mkString "prefer-light";
              cursor-size = mkInt32 32;
            };
            "org/gnome/shell".enabled-extensions = map (e: e.extensionUuid) enabledGnomeExtensions;
            "org/gnome/system/location".enabled = mkBoolean true;
            "org/gnome/desktop/datetime".automatic-timezone = mkBoolean true;
          };
        }];
      };
    };
  };
}
