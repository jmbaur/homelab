{
  network.description = "homelab";
  rhubarb = { config, pkgs, ... }: {
    deployment.targetHost = "rhubarb.lan";
    imports = [ ./lib/nixops.nix ./hosts/rhubarb/configuration.nix ];
  };
  asparagus = { config, pkgs, ... }: {
    deployment.targetHost = "asparagus.lan";
    imports = [ ./lib/nixops.nix ./hosts/asparagus/configuration.nix ];
  };
}
