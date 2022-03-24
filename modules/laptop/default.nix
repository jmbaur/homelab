{ config, lib, pkgs, ... }:
let
  cfg = config.custom.laptop;
in
{
  options.custom.laptop.enable = lib.mkEnableOption "Enable laptop configs";
  config = lib.mkIf cfg.enable {
  };
}
