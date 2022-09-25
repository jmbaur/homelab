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

  services.fail2ban.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  services.webauthn-tiny = {
    enable = true;
    relyingParty = {
      id = "jmbaur.com";
      origin = "https://auth.jmbaur.com";
    };
    nginx = {
      enable = true;
      virtualHost = "auth.jmbaur.com";
      basicAuthFile = config.age.secrets.htpasswd.path;
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "auth.jmbaur.com".useACMEHost = "jmbaur.com";
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
          extraConfig = ''
            auth_request /auth;
            error_page 401 = @error401;
          '';
        };
        locations."= /auth" = {
          proxyPass = "http://localhost:8080/api/validate";
          extraConfig = ''
            proxy_pass_request_body off;
            proxy_set_header Content-Length "";
            proxy_set_header X-Original-URI $request_uri;
          '';
        };
        locations."@error401".return = "302 https://auth.jmbaur.com/?url=https://$http_host&request_uri";
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "jaredbaur@fastmail.com";
    certs."jmbaur.com".extraDomainNames = [ "auth.jmbaur.com" ];
  };
}
