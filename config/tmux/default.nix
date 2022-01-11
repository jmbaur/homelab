{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.tmux;
in
{
  options = {
    custom.tmux = {
      enable = mkEnableOption "Custom tmux settings";
    };
  };

  config = mkIf cfg.enable {
    environment.etc."tmux.conf".source = ../../playbooks/files/tmux.conf;
    environment.systemPackages = [ pkgs.tmux ];
  };

}
