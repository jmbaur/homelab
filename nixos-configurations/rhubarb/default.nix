{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    {
      hardware.rpi4.enable = true;
      boot.kernelPackages = pkgs.linuxPackages_6_11;

      custom.server.enable = true;
      custom.basicNetwork.enable = true;
      custom.nativeBuild = true;
      custom.image = {
        installer.targetDisk = "/dev/mmcblk0";
        boot.uefi.enable = true;
      };
    }
    {
      time.timeZone = null;
      services.automatic-timezoned.enable = true;
      hardware.bluetooth.enable = true;

      services.xserver.desktopManager.kodi.package =
        (pkgs.kodi-gbm.override {
          sambaSupport = false; # deps don't cross-compile
        }).withPackages
          (p: [
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
          ExecStart = lib.getExe' config.services.xserver.desktopManager.kodi.package "kodi-standalone";
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
    }
  ];
}
