{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
{
  options = {
    custom.gui.enable = lib.mkEnableOption "Enable gui config";
    custom.gui.desktop = lib.mkEnableOption "Enable desktop gui config";
  };
  config = lib.mkIf cfg.enable {
    environment.variables.NIXOS_OZONE_WL = "1";
    hardware.pulseaudio.enable = !config.custom.sound.enable;
    hardware.i2c.enable = cfg.desktop;
    location.provider = "geoclue2";
    programs.adb.enable = true;
    programs.dconf.enable = true;
    programs.seahorse.enable = true;
    programs.ssh.startAgent = true;
    xdg.portal.enable = true;
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };
    programs.wshowkeys.enable = true;
    services.avahi.enable = true;
    services.gnome.gnome-keyring.enable = true;
    services.pcscd.enable = false;
    services.printing.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
  };
}
