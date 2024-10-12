{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.kodi.enable = lib.mkEnableOption "kodi";
  config = lib.mkIf config.services.kodi.enable {
    boot.kernelParams = [ "quiet" ];

    time.timeZone = null;
    services.automatic-timezoned.enable = true;
    hardware.bluetooth.enable = true;

    hardware.graphics.enable = true;

    services.xserver.desktopManager.kodi.package =
      (pkgs.kodi-gbm.override {
        sambaSupport = false; # deps don't cross-compile
      }).withPackages
        (p: [
          p.inputstream-adaptive
          p.jellyfin
          p.joystick
        ]);

    users.users.kodi = {
      isSystemUser = true;
      home = "/var/lib/kodi";
      createHome = true;
      group = config.users.groups.kodi.name;
    };
    users.groups.kodi = { };

    systemd.services.kodi = {
      wantedBy = [ "multi-user.target" ];
      conflicts = [ "getty@tty1.service" ];
      serviceConfig = {
        User = "kodi";
        Group = "kodi";
        SupplementaryGroups = [
          "audio"
          "disk"
          "input"
          "tty"
          "video"
        ];
        TTYPath = "/dev/tty1";
        StandardInput = "tty";
        StandardOutput = "journal";
        PAMName = "login";
        ExecStart = toString [
          (lib.getExe' config.services.xserver.desktopManager.kodi.package "kodi-standalone")
        ];
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 8080 ];
      allowedUDPPorts = [ 8080 ];
    };

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    services.upower.enable = true;
  };
}
