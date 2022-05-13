{ config, lib, pkgs, ... }:
with lib;
{
  options.router = {
    guaPrefix = mkOption { type = types.str; };
    ulaPrefix = lib.mkOption { type = types.str; };
  };
}
