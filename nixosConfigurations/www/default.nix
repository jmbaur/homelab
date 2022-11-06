{ config, lib, pkgs, modulesPath, ... }:
let
  wg = import ./wg.nix;
in
{
  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];

  boot.loader.grub.configurationLimit = 2;

  system.stateVersion = "22.11";

  custom = {
    cross-compiled.${config.nixpkgs.system}.enable = true;
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
      "wg/www/www" = {
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
      allowedUDPPorts = [ config.networking.wireguard.interfaces.www.listenPort ];
    };
    wireguard.interfaces.www = {
      privateKeyFile = config.sops.secrets."wg/www/www".path;
      listenPort = 51820;
      ips = [ wg.www.ip ];
      peers = [
        { allowedIPs = [ wg.kale.ip ]; publicKey = wg.kale.publicKey; }
        { allowedIPs = [ wg.rhubarb.ip ]; publicKey = wg.rhubarb.publicKey; }
        { allowedIPs = [ wg.artichoke.ip ]; publicKey = wg.artichoke.publicKey; }
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
          proxyPass = "http://[${wg.rhubarb.ip}]:3000";
          extraConfig = ''
            proxy_set_header Host $host;
          '';
        };
        locations."/api/live" = {
          proxyPass = "http://[${wg.rhubarb.ip}]:3000";
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
                proxyPass = "http://[${wg.${host}.ip}]:19531/";
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
                  ("<!DOCTYPE html>"
                    + (lib.concatMapStrings (host: ''<a href="/${host}/browse">${host}</a><br />'') logHosts));
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
