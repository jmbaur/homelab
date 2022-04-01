{ config, lib, pkgs, ... }:
let
  cfg = config.custom.containers;
in
with lib;
{

  options = {
    custom.containers.enable = mkEnableOption "Enable custom container settings";
  };

  config = mkIf cfg.enable {
    virtualisation.containers = {
      enable = true;
      containersConf.settings.engine.detach_keys = "ctrl-q,ctrl-e";
    };
    virtualisation.podman = {
      enable = true;
      defaultNetwork.dnsname.enable = true;
    };
  };

}
