{
  network.description = "RPI4 running Kodi";
  rhubarb = { config, pkgs, ... }: {
    deployment.targetHost = "rhubarb.lan";
    imports = [ ./configuration.nix ];
  };
}
