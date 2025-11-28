{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    getExe
    mkEnableOption
    mkIf
    mkOption
    optionals
    types
    ;

  cfg = config.custom.ddns;
in
{
  options.custom.ddns = {
    enable = mkEnableOption "ddns";

    interface = mkOption { type = types.str; };

    domain = mkOption { type = types.str; };

    ipv4.enable = mkEnableOption "watch for ipv4 address changes" // {
      default = true;
    };

    ipv6.enable = mkEnableOption "watch for ipv6 address changes" // {
      default = true;
    };

    subdomain = mkOption {
      type = types.str;
      default = config.networking.hostName;
      defaultText = ''config.networking.hostName'';
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.ipwatch_env = { };

    users.groups.cloudflare = { };

    systemd.services.update-cloudflare = {
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        Restart = "on-failure";
        EnvironmentFile = [ config.sops.secrets.ipwatch_env.path ];
        ExecStart = getExe (pkgs.writeShellApplication {
            name = "update-cloudflare";
            runtimeInputs = [
              pkgs.jq
              pkgs.ipwatch
              pkgs.curl
            ];
            text =
              let
                updateCloudflare = name: recordType: ''
                  curl \
                    --silent \
                    --show-error \
                    --request PUT \
                    --header "Content-Type: application/json" \
                    --header "Authorization: Bearer ''${CF_API_TOKEN}" \
                    --data '{"type":"${recordType}","name":"${name}","content":"'"''${ADDR}"'","proxied":false}' \
                    "https://api.cloudflare.com/client/v4/zones/''${CF_ZONE_ID}/dns_records/''${CF_RECORD_ID_${recordType}}" | jq
                '';
              in
              ''
                ipwatch -hook ${cfg.interface}:${
                  concatStringsSep "," (
                    [
                      "IsGlobalUnicast"
                      "!IsPrivate"
                      "!IsLoopback"
                      "!Is4In6"
                    ]
                    ++ optionals (!cfg.ipv4.enable) [ "!Is4" ]
                    ++ optionals (!cfg.ipv6.enable) [ "!Is6" ]
                  )
                } | while read -r json_line; do
                  ADDR=$(echo "$json_line" | jq -r '.address')
                  prefixlen=$(echo "$json_line" | jq -r '.prefixlen')
                  if [[ $prefixlen -gt 32 ]]; then
                    ${updateCloudflare "${cfg.subdomain}.${cfg.domain}" "AAAA"}
                  else
                    ${updateCloudflare "${cfg.subdomain}.${cfg.domain}" "A"}
                  fi
                done
              '';
          });
      };
    };
  };
}
