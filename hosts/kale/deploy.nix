{
  network.description = "kale";
  kale = { config, pkgs, ... }: {
    deployment.targetHost = "kale.lan";
    imports = [ ./secrets.nix ./configuration.nix ];
  };
}
