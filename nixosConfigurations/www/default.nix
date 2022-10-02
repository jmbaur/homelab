{ config, pkgs, modulesPath, inventory, ... }: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

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
      wireguard.interfaces.wg-public = {
        privateKeyFile = config.age.secrets.wg-public-www.path;
        listenPort = wgPublic.id + 51800;
        ips = with wgPublic.hosts.www; [
          "${ipv4}/${toString wgPublic.ipv4Cidr}"
          "${ipv6.ula}/${toString wgPublic.ipv6Cidr}"
          "${ipv6.gua}/${toString wgPublic.ipv6Cidr}"
        ];
        peers = [{
          allowedIPs = with wgPublic.hosts.artichoke; [ "${ipv4}/32" "${ipv6.ula}/128" ];
          publicKey = wgPublic.hosts.artichoke.publicKey;
        }];
      };
    };

  services.webauthn-tiny = {
    enable = true;
    environmentFile = config.age.secrets.webauthn-tiny-env.path;
    relyingParty = {
      id = "jmbaur.com";
      origin = "https://auth.jmbaur.com";
    };
    nginx = {
      enable = true;
      virtualHost = "auth.jmbaur.com";
      basicAuthFile = config.age.secrets.htpasswd.path;
      protectedVirtualHosts = [ "jmbaur.com" "monitoring.jmbaur.com" ];
      useACMEHost = "jmbaur.com";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "monitoring.jmbaur.com" = {
        forceSSL = true;
        useACMEHost = "jmbaur.com";
        locations."/".proxyPass = "http://172.16.20.1:19531";
      };
      "jmbaur.com" = {
        default = true;
        enableACME = true;
        forceSSL = true;
        serverAliases = [ "www.jmbaur.com" ];
        locations."/" = {
          root = pkgs.linkFarm "root" [{
            name = "index.html";
            path = pkgs.writeText "index.html" ''
              <!DOCTYPE html>
              These aren't the droids you're looking for.
            '';
          }];
          index = "index.html";
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "jaredbaur@fastmail.com";
    certs."jmbaur.com".extraDomainNames = [ "auth.jmbaur.com" ];
  };
}
