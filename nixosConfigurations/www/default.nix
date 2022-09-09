{ pkgs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  system.stateVersion = "22.11";

  custom.deployee = {
    enable = true;
    authorizedKeyFiles = [ pkgs.jmbaur-github-ssh-keys ];
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      "www.jmbaur.com" = {
        enableACME = false;
        forceSSL = false;
        locations."/" = { };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "jaredbaur@fastmail.com";
  };
}
