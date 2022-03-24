{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;
in
{
  options.custom.gui.enable = lib.mkEnableOption "Enable gui config";
  config = lib.mkIf cfg.enable {
    fonts.fonts = with pkgs; [ iosevka-bin hack-font ];
    programs.sway.enable = true;
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
    hardware.pulseaudio.enable = false;
    services.geoclue2.enable = true;
    services.avahi.enable = true;
    location.provider = "geoclue2";
    programs.adb.enable = true;
    programs.ssh.startAgent = true;
    programs.gnupg.agent.pinentryFlavor = "gnome3";
    services.printing.enable = true;
    services.pcscd.enable = false;
    services.udev.packages = [ pkgs.yubikey-personalization ];
  };
}
