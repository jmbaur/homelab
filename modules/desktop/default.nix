{ config, lib, pkgs, ... }:
let
  cfg = config.custom.desktop;
in
{
  options.custom.desktop.enable = lib.mkEnableOption "Enable desktop config";
  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      libinput = {
        enable = true;
        touchpad = {
          tapping = true;
          naturalScrolling = true;
          disableWhileTyping = true;
          accelProfile = "flat";
        };
      };
      displayManager.lightdm.enable = true;
      windowManager.i3.enable = true;
      videoDrivers = [ "intel" ];
      deviceSection = ''
        Option "DRI" "2"
        Option "TearFree" "true"
      '';
    };
    fonts.fonts = [ pkgs.hack-font ];
    programs.adb.enable = true;
    programs.dconf.enable = true;
    programs.seahorse.enable = true;
    programs.ssh.startAgent = true;
    programs.wireshark.enable = true;
    services.autorandr.enable = true;
    services.avahi = { enable = true; nssmdns = true; };
    services.dbus.packages = [ pkgs.gcr ];
    services.geoclue2.enable = true;
    services.pcscd.enable = false;
    services.power-profiles-daemon.enable = true;
    services.printing.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
    services.udisks2.enable = true;
    services.upower.enable = true;
  };
}
