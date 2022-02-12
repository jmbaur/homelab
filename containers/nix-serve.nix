{ config, lib, pkgs, ... }: {
  services.nix-serve = {
    enable = true;
    port = 5000;
    openFirewall = true;
    bindAddress = ""; # any addr
    secretKeyFile = "/var/lib/nix-serve/cache-priv-key.pem";
  };
}
