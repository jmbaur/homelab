{ config, lib, pkgs, ... }:
let
  cfg = config.custom.gui;

  wlgreetSwayConfig = pkgs.writeText "wlgreet-sway.config" ''
    exec "${pkgs.greetd.wlgreet}/bin/wlgreet --command sway; swaymsg exit"

    seat '*' hide_cursor 100
    input type:touchpad events disabled
    input type:pointer events disabled

    bindsym Mod4+shift+e exec swaynag \
      -t warning \
      -m "What do you want to do?" \
      -b "Poweroff" "systemctl poweroff" \
      -b "Reboot" "systemctl reboot"

    include /etc/sway/config.d/*
  '';
in
{
  options.custom.gui.enable = lib.mkEnableOption "gui";

  config = lib.mkIf cfg.enable {
    custom.basicNetwork.enable = true;

    hardware.keyboard.qmk.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization pkgs.teensy-udev-rules ];
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "teensy-udev-rules"
    ];

    programs.gnupg.agent.enable = true;
    programs.ssh.startAgent = true;
    programs.wshowkeys.enable = true;
    programs.sway.enable = true;


    hardware.pulseaudio.enable = lib.mkForce false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # Use automatic-timezoned for convenience. This enables geoclue2, which
    # requires avahi to be enabled, so we want to make sure systemd-resolved's
    # mDNS capabilities are disabled when this is the case.
    services.automatic-timezoned.enable = true;
    services.avahi.enable = config.services.geoclue2.enable;
    services.resolved.extraConfig = lib.optionalString config.services.avahi.enable ''
      MulticastDNS=${lib.boolToString false}
    '';

    services.dbus.enable = true;
    services.pcscd.enable = true;
    services.power-profiles-daemon.enable = true;
    services.printing.enable = true;
    services.udisks2.enable = true;
    services.upower.enable = true;

    services.greetd = {
      enable = true;
      vt = 7;
      settings.default_session.command = "sway --config ${wlgreetSwayConfig}";
    };
  };
}
