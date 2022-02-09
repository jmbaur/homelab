{ config, lib, pkgs, ... }:
let
  cfg = config.custom.virtualisation;
in
with lib;
{

  options = {
    custom.virtualisation.enable = mkEnableOption "Enable custom virtualisation options";
    custom.virtualisation.variant = mkOption {
      type = types.enum [ "minimal" "normal" ];
      default = "minimal";
      description = ''
        The "minimal" virtualisation variant only enables containers, while the
        "normal" variant enables that along with a hypervisor.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ buildah skopeo podman-compose ];
    virtualisation.containers = {
      enable = true;
      containersConf.settings.engine.detach_keys = "ctrl-q,ctrl-e";
    };
    virtualisation.podman.enable = true;
    virtualisation.libvirtd = mkIf (cfg.variant == "normal") {
      enable = true;
      allowedBridges = mkForce [ ];
    };
  };

}
