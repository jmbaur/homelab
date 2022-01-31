{ config, lib, pkgs, ... }:
let
  cfg = config.custom.obs;
in
with lib;
{
  options = {
    custom.obs.enable = mkEnableOption "Enable custom OBS studio settings";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [ wlrobs ];
      })
    ];
  };

}
