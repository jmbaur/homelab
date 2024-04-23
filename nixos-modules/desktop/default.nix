{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.desktop;

  startSway = "exec systemd-cat --identifier=sway sway";
in
{
  options.custom.desktop.enable = lib.mkEnableOption "desktop";

  config = lib.mkIf cfg.enable {
    custom.normalUser.enable = true;
    custom.basicNetwork.enable = true;

    hardware.keyboard.qmk.enable = true;
    services.udev.packages = [
      pkgs.yubikey-personalization
      pkgs.teensy-udev-rules
    ];
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "teensy-udev-rules" ];

    programs.sway = {
      enable = true;
      wrapperFeatures = {
        base = true;
        gtk = true;
      };
    };

    hardware.pulseaudio.enable = lib.mkForce false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # Use automatic-timezoned for convenience. This enables geoclue2.
    services.automatic-timezoned.enable = true;

    # It would be uncommon for a desktop system to have an NMEA serial device,
    # plus setting this to true means that geoclue will be dependent on avahi
    # being enabled, since NMEA support in geoclue uses avahi.
    services.geoclue2.enableNmea = lib.mkDefault false;

    services.avahi = {
      enable = config.services.geoclue2.enableNmea;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
        addresses = true; # enable the use of <hostname>.local
      };
    };

    services.resolved.extraConfig = lib.mkIf config.services.avahi.enable ''
      MulticastDNS=${lib.boolToString false}
    '';

    services.dbus.enable = true;
    services.pcscd.enable = true;
    services.power-profiles-daemon.enable = true;
    services.printing.enable = true;
    services.udisks2.enable = true;
    services.upower.enable = true;

    programs.fish.loginShellInit = lib.mkAfter ''
      if test -z "$WAYLAND_DISPLAY" && test "$XDG_VTNR" -eq 1;
        ${startSway}
      end
    '';

    programs.bash.loginShellInit = lib.mkAfter ''
      if test -z "$WAYLAND_DISPLAY" && test "$XDG_VTNR" -eq 1; then
        ${startSway}
      fi
    '';

    programs.zsh.loginShellInit = lib.mkAfter ''
      if test -z "$WAYLAND_DISPLAY" && test "$XDG_VTNR" -eq 1; then
        ${startSway}
      fi
    '';
  };
}
