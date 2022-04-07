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
    services.geoclue2.enable = true;
    services.gnome.gnome-keyring.enable = true;
    services.pcscd.enable = false;
    services.printing.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      windowManager.i3.enable = true;
      xautolock = {
        enable = true;
        locker = "${pkgs.i3lock}/bin/i3lock --color=000000";
        extraOptions = [ "-detectsleep" ];
      };
      deviceSection = ''
        Option "TearFree" "true"
      '';
    };
  };
}
