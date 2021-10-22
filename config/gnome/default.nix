{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.custom.gnome;
in
{

  options = {
    custom.gnome = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable custom gnome settings.
        '';
      };

      laptop = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable laptop specific settings (libinput, etc.).
        '';
      };

    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages =
      (with pkgs.gnomeExtensions; [
        appindicator
        system-monitor
      ]) ++ (with pkgs.gnome;
      [
        pomodoro
      ]);

    programs.gnupg.agent.pinentryFlavor = "gnome3";

    networking.networkmanager.enable = true;

    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
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

    system.userActivationScripts.gnome-terminal.text = ''
      UUID=$(${pkgs.util-linux}/bin/uuidgen)
      ${pkgs.dconf}/bin/dconf dump /org/gnome/terminal/ | ${pkgs.gnugrep}/bin/grep -q GruvboxDark && exit 0
      ${pkgs.dconf}/bin/dconf reset -f /org/gnome/terminal/
      ${pkgs.dconf}/bin/dconf load /org/gnome/terminal/ << EOF
        [legacy/profiles:]
        default='$UUID'
        list=['$UUID']

        [legacy/profiles:/:$UUID]
        allow-bold=true
        audible-bell=false
        background-color='#282828282828'
        bold-color='#ebebdbdbb2b2'
        bold-color-same-as-fg=true
        cursor-background-color='#ebebdbdbb2b2'
        cursor-colors-set=true
        cursor-foreground-color='#282828282828'
        font='Monospace 14'
        foreground-color='#ebebdbdbb2b2'
        palette=['#282828282828', '#cccc24241d1d', '#989897971a1a', '#d7d799992121', '#454585858888', '#b1b162628686', '#68689d9d6a6a', '#a8a899998484', '#929283837474', '#fbfb49493434', '#b8b8bbbb2626', '#fafabdbd2f2f', '#8383a5a59898', '#d3d386869b9b', '#8e8ec0c07c7c', '#ebebdbdbb2b2']
        scrollbar-policy='never'
        use-system-font=false
        use-theme-background=false
        use-theme-colors=false
        use-theme-transparency=false
        visible-name='GruvboxDark'
      EOF
    '';

    services = {
      udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];

      power-profiles-daemon.enable = true;

      upower.enable = true;

      printing.enable = true;

      xserver = {
        enable = true;
        layout = "us";
        xkbOptions = "ctrl:nocaps";
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
        desktopManager.gnome.extraGSettingsOverrides = ''
          [org.gnome.desktop.interface]
          gtk-theme = 'Adwaita-dark'
          gtk-key-theme = 'Emacs'
        '';

        libinput = mkIf cfg.laptop {
          enable = true;
          touchpad = {
            accelProfile = "flat";
            tapping = true;
            naturalScrolling = true;
          };
        };
      };
    };
  };

}
