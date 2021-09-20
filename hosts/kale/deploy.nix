{
  network.description = "kale";
  kale = { config, pkgs, ... }: {
    deployment.targetHost = "kale.lan";
    imports = [ ./configuration.nix ];
  };
}
