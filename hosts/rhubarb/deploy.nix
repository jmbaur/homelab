{
  network.description = "rhubarb";
  rhubarb = { config, pkgs, ... }: {
    deployment.targetHost = "rhubarb.lan";
    imports = [
      ../../lib/nixops.nix
      ./configuration.nix
    ];
  };
}
