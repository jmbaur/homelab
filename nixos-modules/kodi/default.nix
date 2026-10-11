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
            version = "2026.4.9+matrix.1";
            namespace = pname;
            src = fetchzip {
              url = "https://mirrors.kodi.tv/addons/${lib.toLower rel}/plugin.video.mlbtv/plugin.video.mlbtv-${version}.zip";
              hash = "sha256-8BKDajtHI7p087aAZryc0H/SF+81+riVtdhv5VhzYUM=";
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

    jellyfin = {
      server = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "http://jellyfin.internal:8096";
        description = ''
          Jellyfin server that the jellyfin add-on signs in to, without
          prompting, as {option}`services.kodi.jellyfin.user`.
        '';
      };

      user = mkOption {
        type = types.str;
        description = ''
          Jellyfin user without a password to sign in as.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.automatic-timezoned.enable = true;
      hardware.bluetooth.enable = true;

      hardware.graphics.enable = true;

      # Used by libass to find fonts for subtitles
      fonts.fontconfig.enable = true;

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

    (mkIf (cfg.jellyfin.server != null) {
      # Write the add-on's credentials (data.json) before kodi starts, unless
      # the stored token still works for this server.
      systemd.services.kodi-jellyfin-login = {
        description = "Sign the kodi jellyfin add-on in to ${cfg.jellyfin.server}";
        wantedBy = [
          "kodi.service"
          "cage-tty1.service"
        ];
        before = [
          "kodi.service"
          "cage-tty1.service"
        ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = [
          pkgs.curl
          pkgs.jq
        ];
        environment = {
          SERVER = cfg.jellyfin.server;
          JELLYFIN_USER = cfg.jellyfin.user;
          ADDON_VERSION = pkgs.kodiPackages.jellyfin.version;
        };
        serviceConfig = {
          Type = "oneshot";
          User = config.users.users.kodi.name;
          Group = config.users.users.kodi.group;
        };
        script = ''
          dir=${config.users.users.kodi.home}/.kodi/userdata/addon_data/plugin.video.jellyfin
          mkdir -p "$dir"

          # The add-on identifies itself with this device ID
          if [[ ! -s $dir/jellyfin_guid ]]; then
            printf '%s' "$(</proc/sys/kernel/random/uuid)" >"$dir/jellyfin_guid"
          fi
          device_id=$(<"$dir/jellyfin_guid")

          if token=$(jq -er --arg address "$SERVER" \
            '.Servers[] | select(.address == $address) | .AccessToken' "$dir/data.json" 2>/dev/null) &&
            curl -fsS -o /dev/null -H "Authorization: MediaBrowser Token=\"$token\"" "$SERVER/Users/Me"; then
            exit 0
          fi

          info=$(curl -fsS --retry 30 --retry-delay 2 --retry-all-errors "$SERVER/System/Info/Public")
          auth=$(curl -fsS \
            -H "Authorization: MediaBrowser Client=\"Kodi\", Device=\"Kodi\", DeviceId=\"$device_id\", Version=\"$ADDON_VERSION\"" \
            -H 'Content-Type: application/json' \
            -d "$(jq -n --arg user "$JELLYFIN_USER" '{Username: $user, Pw: ""}')" \
            "$SERVER/Users/AuthenticateByName")

          jq -n --arg address "$SERVER" --argjson info "$info" --argjson auth "$auth" '{
            Servers: [{
              AccessToken: $auth.AccessToken,
              DateLastAccessed: (now | todate),
              Id: $auth.ServerId,
              Name: $info.ServerName,
              UserId: $auth.User.Id,
              Users: [{ Id: $auth.User.Id, IsSignedInOffline: true }],
              address: $address
            }]
          }' >"$dir/data.json.tmp"
          mv "$dir/data.json.tmp" "$dir/data.json"
        '';
      };
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
