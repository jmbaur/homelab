{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.custom.git;
in
{
  options = {
    custom.git = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable custom git settings.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.git ];
    environment.etc."gitconfig".source = ./gitconfig;
  };
}
