{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.custom.git;
in
{
  options = {
    custom.git.enable = mkEnableOption "Custom git setup";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.git ];
    environment.etc."gitconfig".source = ./gitconfig;
  };
}
