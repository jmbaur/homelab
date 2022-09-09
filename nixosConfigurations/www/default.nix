{ config, pkgs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  system.stateVersion = "22.11";

  custom.deployee = {
    enable = true;
    authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
  };

  age.secrets = {
    htpasswd = {
      mode = "0440";
      owner = config.services.nginx.user;
      group = config.services.nginx.group;
      file = ../../secrets/htpasswd.age;
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      "jmbaur.com" = {
        default = true;
        enableACME = true;
        forceSSL = true;
        serverAliases = [ "www.jmbaur.com" ];
        basicAuthFile = config.age.secrets.htpasswd.path;
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
  };
}
