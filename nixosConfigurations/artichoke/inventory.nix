{ config, lib, pkgs, ... }:
with lib;
let
  hostType = { name, ... }: {
    options = {
      name = mkOption { type = types.str; default = name; };
      dhcp = mkOption { type = types.bool; default = false; };
      wgPeer = mkOption { type = types.bool; default = false; };
      interface = mkOption { type = types.nullOr types.str; default = null; };
      mac = mkOption { type = types.nullOr types.str; default = null; };
      publicKey = mkOption { type = types.nullOr types.str; default = null; };
      ipv4 = mkOption { type = types.str; };
      ipv6 = {
        gua = mkOption { type = types.str; };
        ula = mkOption { type = types.str; };
      };
    };
  };
  networkType = { name, config, ... }: {
    options = {
      name = mkOption { type = types.str; default = name; };
      domain = mkOption { type = types.str; default = "${config.name}.home.arpa"; };
      hosts = mkOption {
        type = types.attrsOf (types.submodule hostType);
        default = { };
      };
      includeRoutesTo = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      managed = mkOption {
        type = types.bool;
        default = false; # TODO(jared): calculate based on hosts that have DHCP set to true.
      };
      wireguard = mkOption {
        type = types.bool;
        default = false; # TODO(jared): calculate based on hosts that have wireguard set to true.
      };
      id = mkOption { type = types.int; };
      mtu = mkOption { type = types.nullOr types.int; default = null; };
      ipv4Cidr = mkOption { type = types.int; default = 24; };
      ipv6Cidr = mkOption { type = types.int; default = 64; };
      networkGuaCidr = mkOption { type = types.str; };
      networkGuaPrefix = mkOption { type = types.str; };
      networkIPv4 = mkOption { type = types.str; };
      networkIPv4Cidr = mkOption { type = types.str; };
      networkIPv4SignificantBits = mkOption { type = types.str; };
      networkUlaCidr = mkOption { type = types.str; };
      networkUlaPrefix = mkOption { type = types.str; };
    };
  };
in
{
  options.custom.inventory = {
    guaPrefix = mkOption {
      type = types.str;
      description = ''
        The IPv6 Global Unicast Address prefix. This is in the form of the
        first 48 bytes of an IPv6 address (ffff:ffff:ffff).
      '';
    };
    ulaPrefix = mkOption {
      type = types.str;
      description = ''
        The IPv6 Unique Local Address prefix. This is in the form of the first
        48 bytes of an IPv6 address (ffff:ffff:ffff).
      '';
    };
    networks = mkOption {
      type = types.attrsOf (types.submodule networkType);
      default = { };
    };
  };

  config = mkIf (config.custom.inventory != { }) {
    environment.etc."inventory.json".source = (pkgs.formats.json { }).generate
      "inventory.json"
      config.custom.inventory;
  };
}
