{
  network.description = "homelab";
  broccoli = { config, pkgs, ... }: {
    deployment.targetHost = "broccoli.home.arpa.";
    imports = [ ./lib/nixops.nix ./hosts/broccoli/configuration.nix ];
  };
  rhubarb = { config, pkgs, ... }: {
    deployment.targetHost = "rhubarb.home.arpa.";
    imports = [ ./lib/nixops.nix ./hosts/rhubarb/configuration.nix ];
  };
  asparagus = { config, pkgs, ... }: {
    deployment.targetHost = "asparagus.home.arpa.";
    imports = [ ./lib/nixops.nix ./hosts/asparagus/configuration.nix ];
  };
}
