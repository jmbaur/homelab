{
  network.description = "kale";
  kale = { config, pkgs, ... }: {
    deployment.targetHost = "kale.lan";
    # deployment.targetUser = "nixops"; # TODO(jared): getting error
    imports = [ ./configuration.nix ];
  };
}
