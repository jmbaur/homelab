{ config, lib, pkgs, ... }:
let
  cfg = config.custom.desktop;
in
with lib;
{
  options = {
    custom.desktop.enable = mkEnableOption "Enable custom desktop config";
  };

  config = mkIf cfg.enable {
    programs.sway.enable = true; # enables swaylock in pam, dconf, etc.

    xdg.portal = {
      enable = true;
      wlr.enable = true;
    };

    programs.wshowkeys.enable = true;
    programs.adb.enable = true;
    programs.wireshark.enable = true;
    security.rtkit.enable = true;
    services.greetd = {
      enable = true;
      vt = 7;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${pkgs.sway}/bin/sway";
        };
      };
    };
    services.avahi.enable = true;
    services.geoclue2.enable = true;
    services.hardware.bolt.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;
    services.printing.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
      media-session.config.bluez-monitor.rules = [
        {
          # Matches all cards
          matches = [{ "device.name" = "~bluez_card.*"; }];
          actions = {
            "update-props" = {
              "bluez5.reconnect-profiles" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
              # mSBC is not expected to work on all headset + adapter combinations.
              "bluez5.msbc-support" = true;
              # SBC-XQ is not expected to work on all headset + adapter combinations.
              "bluez5.sbc-xq-support" = true;
            };
          };
        }
        {
          matches = [
            # Matches all sources
            { "node.name" = "~bluez_input.*"; }
            # Matches all outputs
            { "node.name" = "~bluez_output.*"; }
          ];
          actions = {
            "node.pause-on-idle" = false;
          };
        }
      ];
    };

  };

}
