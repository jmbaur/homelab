{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
{
  options.custom.gui.enable = lib.mkEnableOption "Enable gui config";
  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      libinput.enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome = {
        enable = true;
        sessionPath = with pkgs.gnomeExtensions; [ night-theme-switcher ];
      };
    };
    qt5 = {
      enable = true;
      platformTheme = "gnome";
    };
    hardware.pulseaudio.enable = false;
    programs.adb.enable = true;
    programs.ssh.startAgent = true;
    programs.gnupg.agent.pinentryFlavor = "gnome3";
    services.printing.enable = true;
    services.pcscd.enable = false;
    services.udev.packages = [ pkgs.yubikey-personalization ];
  };
}
