{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;

  launcher = pkgs.writeShellScript "greetd-launcher" ''
    if command -v greetd-launcher >/dev/null; then
      exec -a "$0" greetd-launcher
    else
      exec -a "$0" "$SHELL"
    fi
  '';
in
{
  options.custom.gui.enable = lib.mkEnableOption "gui";

  config = lib.mkIf cfg.enable {
    custom.basicNetwork.enable = true;

    hardware.keyboard.qmk.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization pkgs.teensy-udev-rules ];

    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [ "teensy-udev-rules" ];

    hardware.pulseaudio.enable = lib.mkForce false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    location.provider = "geoclue2";

    programs.gnupg.agent.enable = true;
    programs.ssh.startAgent = true;
    programs.wshowkeys.enable = true;
    programs.sway = {
      enable = true;
      wrapperFeatures = { base = true; gtk = true; };
    };

    services.automatic-timezoned.enable = true;
    services.avahi.enable = true;
    services.dbus.enable = true;
    services.pcscd.enable = true;
    services.power-profiles-daemon.enable = true;
    services.printing.enable = true;
    services.udisks2.enable = true;
    services.upower.enable = true;

    services.greetd = {
      enable = true;
      vt = 7;
      settings.default_session.command = "${pkgs.greetd.greetd}/bin/agreety --cmd ${launcher}";
    };
  };
}
