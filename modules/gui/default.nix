{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
{
  options.custom.gui.enable = lib.mkEnableOption "Enable gui config";
  config = lib.mkIf cfg.enable {
    xdg.portal = {
      wlr = {
        enable = true;
        settings = {
          screencast = {
            chooser_type = "simple";
            chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
          };
        };
      };
    };
    environment.loginShellInit = ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec sway
      fi
    '';
    hardware.pulseaudio.enable = false;
    location.provider = "geoclue2";
    programs.adb.enable = true;
    programs.dconf.enable = true;
    programs.ssh.startAgent = true;
    programs.sway.enable = true;
    services.avahi.enable = true;
    services.dbus.packages = [ pkgs.gcr ];
    services.geoclue2.enable = true;
    services.pcscd.enable = false;
    services.printing.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
  };
}
