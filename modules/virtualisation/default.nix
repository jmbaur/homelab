{ config, lib, pkgs, ... }:
let
  cfg = config.custom.virtualisation;
in
with lib;
{

  options = {
    custom.virtualisation.enable = mkEnableOption "Enable custom virtualisation options";
  };

  config = mkIf cfg.enable {
    virtualisation = {
      containers = {
        enable = true;
        containersConf.settings.engine.detach_keys = "ctrl-q,ctrl-e";
      };
      podman.enable = true;
      libvirtd.enable = true;
    };

  };

}
