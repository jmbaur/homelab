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

  services.ipwatch = {
    enable = true;
    interfaces = [ config.router.wanInterface ];
    environmentFile = config.sops.secrets.ipwatch_env.path;
    filters = [
      "IsGlobalUnicast"
      "!IsPrivate"
      "!IsLoopback"
      "!Is4In6"
    ];
    hooks =
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
      [
        (lib.getExe (
          pkgs.writeShellScriptBin "update-cloudflare" ''
            if [[ "$IS_IP6" == "1" ]]; then
              ${updateCloudflare "${config.networking.hostName}.jmbaur.com" "AAAA"}
            elif [[ "$IS_IP4" == "1" ]]; then
              ${updateCloudflare "${config.networking.hostName}.jmbaur.com" "A"}
            else
              echo nothing to update
            fi
          ''
        ))
      ];
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
