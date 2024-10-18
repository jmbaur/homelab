{
  config,
  lib,
  pkgs,
  ...
}:

let
  caddyErrorHandling = ''
    handle_errors {
      respond "{err.status_code} {err.status_text}"
    }
  '';
in
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  custom.wgNetwork.nodes.pumpkin = {
    peer = true;
    initiate = true;
    endpointHost = "pumpkin.local";
  };

  sops.secrets.ipwatch_env = { };

  systemd.tmpfiles.settings."10-update-cloudflare".${config.systemd.paths.update-cloudflare.pathConfig.PathChanged}.f =
    { };

  systemd.services.ipwatch.serviceConfig.BindPaths = [
    config.systemd.paths.update-cloudflare.pathConfig.PathChanged
  ];

  services.ipwatch = {
    enable = true;
    hooks.${config.router.wanInterface} = {
      filters = [
        "IsGlobalUnicast"
        "!IsPrivate"
        "!IsLoopback"
        "!Is4In6"
      ];
      program = lib.getExe (
        pkgs.writeShellScriptBin "start-update-cloudflare" ''
          env | grep -e ^IS_IP6= -e ^IS_IP4= -e ^ADDR= >${config.systemd.paths.update-cloudflare.pathConfig.PathChanged}
        ''
      );
    };
  };

  systemd.paths.update-cloudflare = {
    pathConfig.PathChanged = "/run/update-cloudflare";
    wantedBy = [ "paths.target" ];
  };

  systemd.services.update-cloudflare = {
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    serviceConfig = {
      DynamicUser = true;
      EnvironmentFile = [
        config.sops.secrets.ipwatch_env.path
        config.systemd.paths.update-cloudflare.pathConfig.PathChanged
      ];
      Type = "oneshot";
      ExecStart = lib.getExe (
        (pkgs.writeShellApplication {
          name = "update-cloudflare";
          text =
            let
              updateCloudflare = name: recordType: ''
                ${lib.getExe pkgs.curl} \
                  --silent \
                  --show-error \
                  --request PUT \
                  --header "Content-Type: application/json" \
                  --header "Authorization: Bearer ''${CF_API_TOKEN}" \
                  --data '{"type":"${recordType}","name":"${name}","content":"'"''${ADDR}"'","proxied":false}' \
                  "https://api.cloudflare.com/client/v4/zones/''${CF_ZONE_ID}/dns_records/''${CF_RECORD_ID_${recordType}}" | ${lib.getExe pkgs.jq}
              '';
            in
            ''
              if [[ 1 == "''${IS_IP6:-}" ]]; then
                ${updateCloudflare "${config.networking.hostName}.jmbaur.com" "AAAA"}
              elif [[ 1 == "''${IS_IP4:-}" ]]; then
                ${updateCloudflare "${config.networking.hostName}.jmbaur.com" "A"}
              else
                echo "nothing to update"
              fi
            '';
        })
      );
    };
  };

  services.caddy = {
    enable = true;
    email = "jaredbaur@fastmail.com";
    virtualHosts = {
      "music.jmbaur.com".extraConfig = ''
        reverse_proxy http://pumpkin.internal:4533
        ${caddyErrorHandling}
      '';
      "jellyfin.jmbaur.com".extraConfig = ''
        reverse_proxy http://pumpkin.internal:8096
        ${caddyErrorHandling}
      '';
      "photos.jmbaur.com".extraConfig = ''
        reverse_proxy http://pumpkin.internal:2342
        ${caddyErrorHandling}
      '';
    };
  };
}
