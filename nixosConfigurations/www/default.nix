{ config, lib, pkgs, modulesPath, inventory, ... }:
let
  wgPublic = inventory.networks.wg-public;
in
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  boot.loader.grub.configurationLimit = 3;

  # Minimize total build size
  documentation.enable = false;
  fonts.fontconfig.enable = false;

  system.stateVersion = "22.11";

  custom = {
    cross-compiled.enable = true;
    minimal.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      webauthn_tiny_env = { };
      htpasswd = {
        mode = "0440";
        owner = config.services.nginx.user;
        group = config.services.nginx.group;
      };
      "wg/public/www" = {
        mode = "0640";
        group = config.users.groups.systemd-network.name;
      };
    };
  };

  services.fail2ban = {
    enable = true;
    jails.nginx-botsearch = ''
      enabled      = true
      backend      = systemd
      journalmatch = _SYSTEMD_UNIT=nginx.service + _COMM=nginx
    '';
    jails.nginx-http-auth = ''
      enabled      = true
      backend      = systemd
      journalmatch = _SYSTEMD_UNIT=nginx.service + _COMM=nginx
    '';
  };

  networking = {
    firewall = {
      allowedTCPPorts = [ 22 80 443 ];
      allowedUDPPorts = [ (wgPublic.id + 51800) ];
    };
    wireguard.interfaces.${wgPublic.name} = {
      privateKeyFile = config.sops.secrets."wg/public/www".path;
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
    environmentFile = config.sops.secrets.webauthn_tiny_env.path;
    relyingParty = {
      id = "jmbaur.com";
      origin = "https://auth.jmbaur.com";
      extraAllowedOrigins = map (vhost: "https://${vhost}") config.services.webauthn-tiny.nginx.protectedVirtualHosts;
    };
    nginx = {
      enable = true;
      virtualHost = "auth.jmbaur.com";
      useACMEHost = "jmbaur.com";
      basicAuthFile = config.sops.secrets.htpasswd.path;
      protectedVirtualHosts = [ "logs.jmbaur.com" "mon.jmbaur.com" ];
    };
  };

  services.journald.enableHttpGateway = true;
  services.nginx = {
    enable = true;
    statusPage = true;
    commonHttpConfig = ''
      error_log syslog:server=unix:/dev/log;
      access_log syslog:server=unix:/dev/log combined;
    '';
    virtualHosts = {
      # https://grafana.com/tutorials/run-grafana-behind-a-proxy/
      "mon.jmbaur.com" = {
        forceSSL = true;
        useACMEHost = "jmbaur.com";
        locations."/" = {
          proxyPass = "http://[${wgPublic.hosts.rhubarb.ipv6.ula}]:3000";
          extraConfig = ''
            proxy_set_header Host $host;
          '';
        };
        locations."/api/live" = {
          proxyPass = "http://[${wgPublic.hosts.rhubarb.ipv6.ula}]:3000";
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
                proxyPass = "http://[${wgPublic.hosts.${host}.ipv6.ula}]:19531/";
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
                    lib.concatMapStrings
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
