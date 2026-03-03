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
        .${cfg.backend}.override
        { sambaSupport = false; } # deps don't cross-compile
      ).overrideAttrs
      { enableParallelBuilding = true; }
    ).withPackages
      (p: [
        p.inputstream-adaptive
        p.jellyfin
        p.joystick
        p.mediacccde
        p.netflix
        p.youtube

        # TODO(jared): contribute these upstream
        (p.callPackage (
          {
            buildKodiAddon,
            fetchzip,
            rel,
          }:
          buildKodiAddon rec {
            pname = "skin.ftv";
            version = "8.0.1";
            namespace = pname;
            src = fetchzip {
              url = "https://mirrors.kodi.tv/addons/${lib.toLower rel}/skin.ftv/skin.ftv-${version}.zip";
              hash = "sha256-kgVwAnrknpyfc3ViBV3BZ5CCTQCDVxsDIjt7dobV0eA=";
            };
          }
        ) { })
        (p.callPackage (
          {
            buildKodiAddon,
            fetchzip,
            rel,
          }:
          buildKodiAddon rec {
            pname = "plugin.video.archive.org";
            version = "1.0.0";
            namespace = pname;
            src = fetchzip {
              url = "https://mirrors.kodi.tv/addons/${lib.toLower rel}/plugin.video.archive.org/plugin.video.archive.org-${version}.zip";
              hash = "sha256-q/V2L+NjPhwVnlED6ihXaRCmq3m4TH/cpCCxJyIV3QY=";
            };
          }
        ) { })
        (p.callPackage (
          {
            buildKodiAddon,
            fetchzip,
            rel,
            requests,
          }:
          buildKodiAddon rec {
            pname = "plugin.video.mlbtv";
            version = "2025.7.18+matrix.1";
            namespace = pname;
            src = fetchzip {
              url = "https://mirrors.kodi.tv/addons/${lib.toLower rel}/plugin.video.mlbtv/plugin.video.mlbtv-${version}.zip";
              hash = "sha256-VuTlUr5jiyhx5VAkaCjA85zpYsyLT7BHGjR6gs3emGc=";
            };
            propagatedBuildInputs = [ requests ];
          }
        ) { })
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
        useDefaultShell = true;
        group = config.users.groups.kodi.name;
      };
      users.groups.kodi = { };
    }

    (mkIf (cfg.backend == "gbm") {
      # TODO(jared): We shouldn't have to do this, though
      # switch-to-configuration is flawed in that if getty@.service changes
      # between configurations, it will be restarted, killing kodi.
      systemd.services."getty@tty1".enable = false;

      systemd.services.kodi = mkMerge [
        commonSystemdSettings
        {
          wantedBy = [ "multi-user.target" ];
          conflicts = [ "getty@tty1.service" ];

          serviceConfig = {
            User = "kodi";
            Group = "kodi";
            TTYPath = "/dev/tty1";
            TTYReset = "yes";
            TTYVHangup = "yes";
            TTYVTDisallocate = "yes";
            StandardInput = "tty-fail";
            StandardOutput = "journal";
            StandardError = "journal";
            PAMName = "kodi";
            Restart = "always";
            ExecStart = toString [
              (getExe' kodiPackage "kodi-standalone")
            ];
          };
        }
      ];

      # systemd 258 defaults this to user-light, which means the user systemd
      # instance is never started and things like audio (which run as a user
      # service) don't work.
      security.pam.services.kodi.text = ''
        auth    required pam_unix.so nullok
        account required pam_unix.so
        session required pam_unix.so
        session required pam_env.so conffile=/etc/pam/environment readenv=0
        session required ${config.systemd.package}/lib/security/pam_systemd.so class=user
      '';
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
