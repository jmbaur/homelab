{ config, lib, pkgs, ... }:

let
  cfg = config.custom.cache;
in
with lib;
{
  options.custom.cache.enable = mkEnableOption "Custom Nix binary cache";
  config = mkIf cfg.enable {
    nix.settings.substituters = [ "https://cache.jmbaur.com/" ];
    nix.settings.trusted-public-keys = [ "cache.jmbaur.com:Zw4UQwDtZLWHgNrgKiwIyMDWsBVLvtDMg3zcebvgG8c=" ];
  };
}
