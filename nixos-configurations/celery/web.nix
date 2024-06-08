{ pkgs, ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "jaredbaur@fastmail.com";
    certs."jmbaur.com".extraDomainNames = map (subdomain: "${subdomain}.jmbaur.com") [
      "www"
      "music"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  custom.wgNetwork.nodes.potato.enable = true;

  services.nginx = {
    enable = true;
    virtualHosts = {
      "jmbaur.com" = {
        forceSSL = true;
        # Only enable ACME on the root, all other subdomains should use
        # `useACMEHost`.
        enableACME = true;
        serverAliases = [ "www.jmbaur.com" ];
        locations."/".root = pkgs.runCommand "www-root" { } ''
          mkdir -p $out
          echo "<h1>Under construction!</h1>" > $out/index.html
        '';
      };

      "music.jmbaur.com" = {
        forceSSL = true;
        useACMEHost = "jmbaur.com";
        locations."/".proxyPass = "potato.internal:4533";
      };
    };
  };
}
