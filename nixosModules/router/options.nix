{ config, lib, pkgs, ... }:
with lib;
let
  hostType = { name, ... }: {
    options = {
      name = mkOption { type = types.str; default = name; };
      dhcp = mkOption { type = types.bool; default = false; };
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
      name = mkOption {
        type = types.str;
        default = name;
        description = ''
          The name of the network.
        '';
      };
      physical = {
        enable = mkEnableOption "physical network";
        interface = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            The name of the physical interface that will be used for this network.
          '';
        };
      };
      wireguard = {
        enable = mkEnableOption "wireguard network";
        publicKey = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            The wireguard public key of the router for this network.
          '';
        };
      };
      domain = mkOption {
        type = types.str;
        default = "${config.name}.home.arpa";
        description = ''
          The domain name of the network.
        '';
      };
      hosts = mkOption {
        type = types.attrsOf (types.submodule hostType);
        default = { };
        description = ''
          The hosts that belong in this network.
        '';
      };
      includeRoutesTo = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Names of other networks that this network should have routes
          configured for. Routes to these networks will be handed out via
          DHCPv4 and IPv6 RA.
        '';
      };
      id = mkOption { type = types.int; };
      mtu = mkOption { type = types.nullOr types.int; default = null; };
      # TODO(jared): Have all of this be calculated so it does not need to be
      # in the configuration.
      ipv4Cidr = mkOption { type = types.int; default = 24; };
      ipv6Cidr = mkOption { type = types.int; default = 64; };
      networkIPv4 = mkOption { type = types.str; };
      networkIPv4Cidr = mkOption { type = types.str; };
      networkIPv4SignificantBits = mkOption { type = types.str; };
      networkGuaCidr = mkOption { type = types.str; };
      networkGuaPrefix = mkOption { type = types.str; };
      networkUlaCidr = mkOption { type = types.str; };
      networkUlaPrefix = mkOption { type = types.str; };
    };
  };
in
{
  options.custom.inventory = {
    networks = mkOption {
      type = types.attrsOf (types.submodule networkType);
      default = { };
      description = ''
        The networks to be configured by the router.
      '';
    };
    # TODO(jared): Make these options a list of hex strings?
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
  };

  config = mkIf (config.custom.inventory != { }) {
    assertions = [{
      message = "Cannot have physical.enable and wireguard.enable set for the same network";
      assertion = (lib.filterAttrs
        (_: network: network.physical.enable && network.wireguard.enable)
        config.custom.inventory.networks) != { };
    }];

    environment.etc."inventory.json".source = (pkgs.formats.json { }).generate
      "inventory.json"
      config.custom.inventory;
  };
}
