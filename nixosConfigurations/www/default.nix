{ config, lib, pkgs, modulesPath, inventory, ... }: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  # Minimize total build size
  documentation.enable = false;
  fonts.fontconfig.enable = false;

  system.stateVersion = "22.11";

  custom = {
    minimal.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
  };

  age.secrets = {
    webauthn-tiny-env.file = ../../secrets/webauthn-tiny-env.age;
    htpasswd = {
      mode = "0440";
      owner = config.services.nginx.user;
      group = config.services.nginx.group;
      file = ../../secrets/htpasswd.age;
    };
    wg-public-www = {
      mode = "0640";
      group = config.users.groups.systemd-network.name;
      file = ../../secrets/wg-public-www.age;
    };
  };

  services.fail2ban.enable = true;
  networking =
    let
      wgPublic = inventory.networks.wg-public;
    in
    {
      firewall = {
        allowedTCPPorts = [ 22 80 443 ];
        allowedUDPPorts = [ (wgPublic.id + 51800) ];
      };
      wireguard.interfaces.${wgPublic.name} = {
        privateKeyFile = config.age.secrets.wg-public-www.path;
        listenPort = wgPublic.id + 51800;
        ips = with wgPublic.hosts.www; [
          "${ipv4}/${toString wgPublic.ipv4Cidr}"
          "${ipv6.ula}/${toString wgPublic.ipv6Cidr}"
        ];
        postSetup = ''
          printf "nameserver ${wgPublic.hosts.artichoke.ipv4}\nnameserver ${wgPublic.hosts.artichoke.ipv6.ula}" | ${pkgs.openresolv}/bin/resolvconf -a ${wgPublic.name} -m 0
        '';
        peers = [
          (with wgPublic.hosts.kale; {
            allowedIPs = [ "${ipv4}/32" "${ipv6.ula}/128" ];
            publicKey = publicKey;
          })
          (with wgPublic.hosts.rhubarb; {
            allowedIPs = [ "${ipv4}/32" "${ipv6.ula}/128" ];
            publicKey = publicKey;
          })
          (with wgPublic.hosts.artichoke; {
            allowedIPs = [ "${ipv4}/32" "${ipv6.ula}/128" ];
            publicKey = publicKey;
          })
        ];
      };
    };

  services.webauthn-tiny = {
    enable = true;
    environmentFile = config.age.secrets.webauthn-tiny-env.path;
    relyingParty = {
      id = "jmbaur.com";
      origin = "https://auth.jmbaur.com";
      extraAllowedOrigins = map (vhost: "https://${vhost}") config.services.webauthn-tiny.nginx.protectedVirtualHosts;
    };
    nginx = {
      enable = true;
      virtualHost = "auth.jmbaur.com";
      useACMEHost = "jmbaur.com";
      basicAuthFile = config.age.secrets.htpasswd.path;
      protectedVirtualHosts = [ "logs.jmbaur.com" "mon.jmbaur.com" ];
    };
  };

  services.journald.enableHttpGateway = true;
  services.nginx = {
    enable = true;
    virtualHosts = {
      # https://grafana.com/tutorials/run-grafana-behind-a-proxy/
      "mon.jmbaur.com" = {
        forceSSL = true;
        useACMEHost = "jmbaur.com";
        locations."/" = {
          proxyPass = "http://rhubarb.wg-public.home.arpa:3000";
          extraConfig = ''
            proxy_set_header Host $host;
          '';
        };
        locations."/api/live" = {
          proxyPass = "http://rhubarb.wg-public.home.arpa:3000";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $host;
          '';
        };
      };
      "logs.jmbaur.com" =
        let
          logHosts = [ "artichoke" "rhubarb" "www" "kale" ];
          locationBlocks = {
            locations = lib.listToAttrs (map
              (host: lib.nameValuePair "/${host}/" {
                proxyPass = "http://${host}.wg-public.home.arpa:19531/";
              })
              logHosts);
          };
        in
        lib.recursiveUpdate locationBlocks {
          forceSSL = true;
          useACMEHost = "jmbaur.com";
          locations."/" = {
            root = pkgs.linkFarm "root" [
              {
                name = "index.html";
                path = pkgs.writeText "index.html"
                  ("<!DOCTYPE html>" + (
                    lib.concatMapStringsSep "\n"
                      (host: ''<a href="/${host}/browse">${host}</a><br />'')
                      logHosts)
                  );
              }
              { name = "favicon.ico"; path = "${./logs_favicon.ico}"; }
            ];
          };
        };
      "jmbaur.com" = {
        default = true;
        enableACME = true;
        forceSSL = true;
        serverAliases = [ "www.jmbaur.com" ];
        locations."/" = {
          root = pkgs.linkFarm "root" [
            {
              name = "index.html";
              path = pkgs.writeText "index.html" ''
                <!DOCTYPE html>
                <p>These aren't the droids you're looking for.</p>
              '';
            }
            {
              name = "robots.txt";
              path = pkgs.writeText "robots.txt" ''
                User-agent: * Disallow: /
              '';
            }
          ];
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "jaredbaur@fastmail.com";
    certs."jmbaur.com".extraDomainNames = map (subdomain: "${subdomain}.jmbaur.com") [
      "auth"
      "logs"
      "mon"
    ];
  };
}
