{ config, lib, pkgs, ... }:
with lib;
let
  interfaceOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
      };
      router = mkOption {
        type = types.str;
      };
      dns = mkOption {
        type = types.str;
      };
      subnet = mkOption {
        type = types.str;
      };
      netmask = mkOption {
        type = types.str;
      };
      start = mkOption {
        type = types.str;
      };
      end = mkOption {
        type = types.str;
      };
      broadcast = mkOption {
        type = types.str;
      };
    };
    config = {
      name = mkDefault name;
    };
  };
in
{
  options = {
    custom.dhcpd4.interfaces = mkOption {
      default = { };
      type = with types; attrsOf (submodule interfaceOpts);
    };
  };

}
