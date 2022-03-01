{ config, lib, pkgs, ... }:

let
  cfg = config.custom.cache;
in
with lib;
{
  options.custom.cache.enable = mkEnableOption "Custom Nix binary cache";
  config = mkIf cfg.enable {
    nix.settings.substituters = [ "https://cache.jmbaur.com/" ];
    nix.settings.trusted-public-keys = [ "cache.jmbaur.com:LE/1LqTlBCweeQmn/3j7HPBdn9vQSPumfijCO4Pa1Gw=" ];
  };
}
