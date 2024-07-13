{
  config,
  lib,
  pkgs,
  ...
}:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "jaredbaur@fastmail.com";
    certs."www.jmbaur.com".extraDomainNames = map (subdomain: "${subdomain}.jmbaur.com") [
      "music"
      "update"
    ];
  };

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

  services.nginx = {
    enable = true;

    commonHttpConfig = ''
      error_log syslog:server=unix:/dev/log;
      access_log syslog:server=unix:/dev/log combined;
    '';

    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      _ = {
        default = true;
        locations."/".return = 404;
      };

      "www.jmbaur.com" = {
        forceSSL = true;
        # Only enable ACME on this subdomain, all other subdomains should use
        # `useACMEHost`.
        enableACME = true;
        locations."/".root = pkgs.runCommand "www-root" { } ''
          mkdir -p $out
          echo "<h1>Under construction!</h1>" > $out/index.html
        '';
      };

      "music.jmbaur.com" = {
        forceSSL = true;
        useACMEHost = "www.jmbaur.com";
        locations."/".proxyPass = "http://potato.internal:4533";
      };

      "update.jmbaur.com" = {
        forceSSL = true;
        useACMEHost = "www.jmbaur.com";
        locations."/".proxyPass = "http://potato.internal:8787";
      };
    };
  };
}
