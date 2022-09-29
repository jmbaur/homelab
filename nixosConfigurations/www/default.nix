{ config, pkgs, modulesPath, ... }: {
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
  };

  services.fail2ban.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

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
      protectedVirtualHosts = [ "jmbaur.com" ];
      useACMEHost = "jmbaur.com";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
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
