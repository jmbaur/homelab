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
        (pkgs.kodi.override {
          gbmSupport = true;
          pipewireSupport = true;
          sambaSupport = false; # deps don't cross-compile
          waylandSupport = true;
          x11Support = false;
        }).withPackages
          (p: [
            p.joystick
          ]);

      users.users.kodi = {
        isSystemUser = true;
        home = "/var/lib/kodi";
        createHome = true;
        group = config.users.groups.kodi.name;
        extraGroups = [
          "audio"
          "disk"
          "input"
          "tty"
          "video"
        ];
      };
      users.groups.kodi = { };

      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.user == "kodi") {
            polkit.log("action=" + action);
            polkit.log("subject=" + subject);
            if (action.id.indexOf("org.freedesktop.login1.") == 0) {
              return polkit.Result.YES;
            }
            if (action.id.indexOf("org.freedesktop.udisks.") == 0) {
              return polkit.Result.YES;
            }
            if (action.id.indexOf("org.freedesktop.udisks2.") == 0) {
              return polkit.Result.YES;
            }
          }
        });
      '';

      services.udev.extraRules = ''
        SUBSYSTEM=="vc-sm",GROUP="video",MODE="0660"
        KERNEL=="vchiq",GROUP="video",MODE="0660"
        SUBSYSTEM=="tty",KERNEL=="tty[0-9]*",GROUP="tty",MODE="0660"
        SUBSYSTEM=="dma_heap",KERNEL=="linux*",GROUP="video",MODE="0660"
        SUBSYSTEM=="dma_heap",KERNEL=="system",GROUP="video",MODE="0660"
      '';

      # systemd.defaultUnit = "graphical.target";
      # systemd.services.kodi = {
      #   description = "Description=Kodi standalone (GBM)";
      #   aliases = [ "display-manager.service" ];
      #   conflicts = [ "getty@tty1.service" ];
      #   wants = [
      #     "polkit.service"
      #     "upower.service"
      #   ];
      #   after = [
      #     "remote-fs.target"
      #     "systemd-user-sessions.service"
      #     "nss-lookup.target"
      #     "sound.target"
      #     "bluetooth.target"
      #     "polkit.service"
      #     "upower.service"
      #     "mysqld.service"
      #     "lircd.service"
      #   ];
      #   serviceConfig = {
      #     User = "kodi";
      #     Group = "kodi";
      #     PAMName = "login";
      #     Restart = "on-abort";
      #     StandardInput = "tty";
      #     StandardOutput = "journal";
      #     TTYPath = "/dev/tty1";
      #     ExecStart = "${lib.getExe config.services.xserver.desktopManager.kodi.package} --standalone --windowing=gbm";
      #   };
      # };

      networking.firewall = {
        allowedTCPPorts = [ 8080 ];
        allowedUDPPorts = [ 8080 ];
      };

      services.cage = {
        enable = true;
        user = config.users.users.kodi.name;
        program = lib.getExe' config.services.xserver.desktopManager.kodi.package "kodi-standalone";
      };

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
    }
  ];
}
