{
  config,
  lib,
  pkgs,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  custom.wgNetwork.nodes.potato.enable = true;

  sops.secrets.ipwatch_env = { };

  services.ipwatch = {
    enable = true;
    interfaces = [ config.router.wanInterface ];
    hookEnvironmentFile = config.sops.secrets.ipwatch_env.path;
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
            "https://api.cloudflare.com/client/v4/zones/''${CF_ZONE_ID}/dns_records/''${CF_RECORD_ID_${recordType}}" | ${pkgs.jq}/bin/jq
        '';
        script = pkgs.writeShellScript "update-cloudflare" ''
          if [[ "$IS_IP6" == "1" ]]; then
            ${updateCloudflare "${config.networking.hostName}.jmbaur.com" "AAAA"}
          elif [[ "$IS_IP4" == "1" ]]; then
            ${updateCloudflare "${config.networking.hostName}.jmbaur.com" "A"}
          else
            echo nothing to update
          fi
        '';
      in
      [
        "internal:echo"
        "executable:${script}"
      ];
  };

  services.caddy = {
    enable = true;
    email = "jaredbaur@fastmail.com";
    virtualHosts = {
      "update.jmbaur.com".extraConfig = ''
        reverse_proxy http://potato.internal:8787
      '';
      "music.jmbaur.com".extraConfig = ''
        reverse_proxy http://potato.internal:4533
      '';
    };
  };
}
