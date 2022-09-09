{ modulesPath, ... }: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  system.stateVersion = "22.11";

  services.nginx = {
    enable = true;
    virtualHosts = {
      "www.jmbaur.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = { };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "jaredbaur@fastmail.com";
  };
}
