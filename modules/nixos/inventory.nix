{ lib, ... }:
with lib;
let
  networkType = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = name;
      };
      domain = mkOption {
        type = types.str;
        default = "${config.name}.home.arpa";
      };
      hosts = mkOption {
        type = types.attrs; # TODO(jared): expand on this
        default = { };
      };
      id = mkOption {
        type = types.int;
      };
      includeRoutesTo = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      ipv4Cidr = mkOption {
        type = types.int;
        default = 24;
      };
      ipv6Cidr = mkOption {
        type = types.int;
        default = 64;
      };
      managed = mkOption {
        type = types.bool;
        default = false; # TODO(jared): calculate based on hosts that have DHCP set to true.
      };
      mtu = mkOption {
        type = types.int;
        default = 1500;
      };
      wireguard = mkOption {
        type = types.bool;
        default = false; # TODO(jared): calculate based on hosts that have wireguard set to true.
      };
    };
  };
in
{
  options.custom.inventory = mkOption {
    type = {
      guaPrefix = mkOption {
        type = types.str;
        description = ''
          The IPv6 Globally Unique Address prefix. This is in the form of the
          first 48 bytes of an IPv6 address (ffff:ffff:ffff).
        '';
      };
      ulaPrefix = mkOption {
        type = types.str;
        description = ''
          The IPv6 Unique Local Address prefix. This is in the form of the
          first 48 bytes of an IPv6 address (ffff:ffff:ffff).
        '';
      };
      networks = mkOption {
        type = types.attrsOf (types.submodule networkType);
        default = { };
      };
    };
    default = { };
  };
}
