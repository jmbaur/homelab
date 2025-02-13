{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.kodi.enable = lib.mkEnableOption "kodi";
  config = lib.mkIf config.services.kodi.enable {
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
          (p.buildKodiAddon {
            name = "subsonic-plugin";
            namespace = "plugin.audio.subsonic";
            src = pkgs.fetchFromGitHub {
              owner = "warwickh";
              repo = "plugin.audio.subsonic";
              rev = "4fffcd143e24852ac5d7ab11df2323fd8e504cbc";
              hash = "sha256-RklVMm+CX1jWeJn3d1WtMGrlLTGyIllBZql/iol82Eo=";
            };
          })
          (p.buildKodiAddon {
            name = "spotify-plugin";
            namespace = "plugin.audio.spotify";
            src = pkgs.fetchFromGitHub {
              owner = "glk1001";
              repo = "plugin.audio.spotify";
              rev = "v1.3.11";
              hash = "sha256-qztV5+sqWzkXMn3MVNSSTMlvW4eCreBmkXH8wi+1TNc=";
            };
          })
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
          "dialout" # needed for pulse-eight CEC adapter
          "disk"
          "input"
          "tty"
          "video"
        ];
        TTYPath = "/dev/tty1";
        StandardInput = "tty";
        StandardOutput = "journal";
        PAMName = "login";
        Restart = "always";
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

    security.rtkit.enable = lib.mkDefault true;

    services.upower.enable = true;
  };
}
