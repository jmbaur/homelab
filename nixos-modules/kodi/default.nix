{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    mkDefault
    getExe'
    mkMerge
    ;

  cfg = config.services.kodi;

  commonSystemdSettings = {
    serviceConfig.SupplementaryGroups = [
      "audio"
      "dialout" # needed for pulse-eight CEC adapter
      "disk"
      "input"
      "tty"
      "video"
    ];
  };

  kodiPackage =
    (
      (
        {
          gbm = pkgs.kodi-gbm;
          wayland = pkgs.kodi-wayland;
        }
        .${cfg.backend}
      ).override
      {
        sambaSupport = false; # deps don't cross-compile
      }
    ).withPackages
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
in
{
  options.services.kodi = {
    enable = mkEnableOption "kodi";
    backend = mkOption {
      type = types.enum [
        "gbm"
        "wayland"
      ];
      default = "gbm";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.automatic-timezoned.enable = true;
      hardware.bluetooth.enable = true;

      hardware.graphics.enable = true;

      networking.firewall = {
        allowedTCPPorts = [ 8080 ];
        allowedUDPPorts = [ 8080 ];
      };

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };

      security.rtkit.enable = mkDefault true;

      services.upower.enable = true;

      users.users.kodi = {
        isSystemUser = true;
        home = "/var/lib/kodi";
        createHome = true;
        group = config.users.groups.kodi.name;
      };
      users.groups.kodi = { };
    }

    (mkIf (cfg.backend == "gbm") {
      systemd.services.kodi = mkMerge [
        commonSystemdSettings
        {
          wantedBy = [ "multi-user.target" ];
          conflicts = [ "getty@tty1.service" ];
          serviceConfig = {
            User = "kodi";
            Group = "kodi";
            TTYPath = "/dev/tty1";
            StandardInput = "tty";
            StandardOutput = "journal";
            PAMName = "login";
            Restart = "always";
            ExecStart = toString [
              (getExe' kodiPackage "kodi-standalone")
            ];
          };
        }
      ];
    })

    (mkIf (cfg.backend == "wayland") {
      services.cage = {
        enable = true;
        user = config.users.users.kodi.name;
        program = getExe' kodiPackage "kodi-standalone";
      };

      systemd.services."cage-tty1" = commonSystemdSettings;
    })
  ]);
}
