{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
{
  options.custom.gui.enable = lib.mkEnableOption "Enable gui config";
  config = lib.mkIf cfg.enable {
    hardware.pulseaudio.enable = !config.custom.sound.enable;
    location.provider = "geoclue2";
    programs.adb.enable = true;
    programs.dconf.enable = true;
    programs.seahorse.enable = true;
    programs.ssh.startAgent = true;
    services.avahi.enable = true;
    services.blueman.enable = config.hardware.bluetooth.enable;
    services.geoclue2.enable = true;
    services.gnome.gnome-keyring.enable = true;
    services.pcscd.enable = false;
    services.printing.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
    services.physlock.enable = true;
    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      windowManager.i3.enable = true;
      libinput = {
        enable = true;
        mouse.accelProfile = "flat";
        touchpad = {
          disableWhileTyping = true;
          naturalScrolling = true;
          tapping = true;
        };
      };
      deviceSection = ''
        Option "TearFree" "true"
      '';
    };
  };
}
