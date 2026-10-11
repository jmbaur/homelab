{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    elem
    getExe
    mkBefore
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.custom.jellyfin;

  xmlstarlet = getExe pkgs.xmlstarlet;
  configDir = lib.escapeShellArg config.services.jellyfin.configDir;
  dataDir = lib.escapeShellArg config.services.jellyfin.dataDir;
  apiKeyFile = "${dataDir}/nixos-api-key";
in
{
  options.custom.jellyfin = {
    enable = mkEnableOption "jellyfin, served by nginx";

    domain = mkOption {
      type = types.str;
      description = ''
        Domain of the nginx virtual host that proxies to jellyfin. TLS
        settings are left to the host.
      '';
    };

    uplinkMbps = mkOption {
      type = types.ints.positive;
      description = ''
        Upload bandwidth of the server's internet connection, used to cap the
        bitrate of streams to remote clients.
      '';
    };

    localClients = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Addresses of clients that jellyfin treats as being on the local
        network, in place of its default private ranges. Local clients are not
        subject to the remote bitrate limit, and can sign in as
        {option}`custom.jellyfin.localUser`.
      '';
    };

    localUser = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Name of a non-admin user without a password, which can only sign in
        from {option}`custom.jellyfin.localClients`. Created if missing.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.jellyfin.enable = true;

      # The jellyfin module doesn't manage system.xml or network.xml, so set
      # the remote streaming bitrate limit (bits/s) here, leaving headroom on
      # the uplink, and trust nginx's X-Forwarded-For so that the limit applies
      # to remote clients (otherwise every client is ::1, and local). mkBefore
      # since the module's encoding.xml preStart may exit early.
      systemd.services.jellyfin.preStart =
        let
          remoteBitrateLimit = cfg.uplinkMbps * 1000 * 1000 * 3 / 4;

          setStrings =
            path: values:
            [
              "--delete"
              "${path}/string"
            ]
            ++ lib.concatMap (value: [
              "--subnode"
              path
              "--type"
              "elem"
              "--name"
              "string"
              "--value"
              value
            ]) values;

          networkEdits =
            setStrings "/NetworkConfiguration/KnownProxies" [ "::1" ]
            ++ lib.optionals (cfg.localClients != [ ]) (
              setStrings "/NetworkConfiguration/LocalNetworkSubnets" (
                map (address: address + (if lib.hasInfix ":" address then "/128" else "/32")) cfg.localClients
              )
            );
        in
        mkBefore ''
          systemXml=${configDir}/system.xml
          if [[ -e $systemXml ]]; then
            ${xmlstarlet} edit --inplace \
              --update /ServerConfiguration/RemoteClientBitrateLimit \
              --value ${toString remoteBitrateLimit} "$systemXml"
          fi

          networkXml=${configDir}/network.xml
          if [[ -e $networkXml ]]; then
            ${xmlstarlet} edit --inplace ${lib.escapeShellArgs networkEdits} "$networkXml"
          fi
        '';

      services.nginx = {
        enable = true;
        virtualHosts.${cfg.domain}.locations."/" = {
          proxyPass = "http://[::1]:8096";
          proxyWebsockets = true;
        };
      };
    }

    (mkIf (cfg.localUser != null) {
      assertions = [
        {
          assertion = cfg.localClients != [ ];
          message = "custom.jellyfin.localUser requires custom.jellyfin.localClients";
        }
      ];

      # Jellyfin has no way to declare API keys, so insert one for
      # jellyfin-local-user while jellyfin is stopped. API keys have admin
      # rights. The database doesn't exist until jellyfin's first start.
      systemd.services.jellyfin.preStart = mkBefore ''
        db=${dataDir}/data/jellyfin.db
        if [[ -e $db ]]; then
          if [[ ! -s ${apiKeyFile} ]]; then
            (umask 077; od -An -tx1 -N16 /dev/urandom | tr -d ' \n' > ${apiKeyFile})
          fi
          ${getExe pkgs.sqlite} "$db" "
            INSERT INTO ApiKeys (DateCreated, DateLastActivity, Name, AccessToken)
            SELECT datetime('now'), datetime('now'), 'nixos', '$(<${apiKeyFile})'
            WHERE NOT EXISTS (SELECT 1 FROM ApiKeys WHERE AccessToken = '$(<${apiKeyFile})');
          "
        fi
      '';

      systemd.services.jellyfin-local-user = {
        description = "Create the jellyfin user for local clients";
        wantedBy = [ "jellyfin.service" ];
        requires = [ "jellyfin.service" ];
        after = [ "jellyfin.service" ];
        partOf = [ "jellyfin.service" ];
        path = [
          pkgs.curl
          pkgs.jq
        ];
        serviceConfig = {
          Type = "oneshot";
          User = config.services.jellyfin.user;
          Group = config.services.jellyfin.group;
        };
        script = ''
          set -o pipefail

          api() {
            curl -fsS \
              -H "Authorization: MediaBrowser Token=\"$(<${apiKeyFile})\"" \
              -H 'Content-Type: application/json' \
              "http://[::1]:8096$1" "''${@:2}"
          }

          # /health returns 200 with "Degraded" while jellyfin is starting up,
          # during which the API returns 503.
          for _ in {1..120}; do
            [[ $(curl -sS 'http://[::1]:8096/health') == Healthy ]] && break
            sleep 1
          done

          name=${lib.escapeShellArg cfg.localUser}

          id=$(api /Users | jq -r --arg name "$name" '.[] | select(.Name == $name) | .Id')
          if [[ -z $id ]]; then
            id=$(api /Users/New -d "$(jq -n --arg name "$name" '{Name: $name}')" | jq -r .Id)
          fi

          api "/Users/$id" | jq '.Policy
            | .IsAdministrator = false
            | .IsHidden = true
            | .EnableRemoteAccess = false
            | .EnableContentDeletion = false' |
            api "/Users/$id/Policy" -d @-
        '';
      };
    })

    # Transcode with NVENC/NVDEC when the NVIDIA driver is in use.
    (mkIf (elem "nvidia" config.services.xserver.videoDrivers) {
      # Populates /run/opengl-driver with libcuda etc.
      hardware.graphics.enable = true;

      services.jellyfin = {
        # Overwrite the existing encoding.xml so these settings take effect
        forceEncodingConfig = true;
        hardwareAcceleration = {
          enable = true;
          type = "nvenc";
          device = "/dev/nvidia0";
        };
        transcoding = {
          enableToneMapping = true;
          enableHardwareEncoding = true;
          # Supported by NVDEC since Pascal. AV1 decoding (Ampere and newer)
          # and encoding (Ada and newer) are left off.
          hardwareDecodingCodecs = {
            h264 = true;
            hevc = true;
            hevc10bit = true;
            vp9 = true;
            mpeg2 = true;
            vc1 = true;
            vp8 = true;
          };
          hardwareEncodingCodecs.hevc = true;
        };
      };

      # The jellyfin module only allows a single device
      systemd.services.jellyfin.serviceConfig.DeviceAllow = [
        "/dev/nvidiactl rw"
        "/dev/nvidia-uvm rw"
        "/dev/nvidia-uvm-tools rw"
      ];
    })
  ]);
}
