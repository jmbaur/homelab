{ options, config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom.inventory;

  hostType = { name, ... }: {
    options = {
      name = mkOption { type = types.str; default = name; };
      dhcp = mkEnableOption "dhcp-enabled host";
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
  policyType = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = name;
        description = ''
          The name of the network this policy will apply to. If the name of the
          network is "default", the policy will apply globally.
        '';
      };
      allowAll = mkEnableOption "allow all traffic";
      includeRouteTo = mkOption {
        type = types.bool;
        default = config.allowAll;
        description = ''
          Whether to advertise a route for the network owning this policy to
          the network described in this policy.
        '';
      };
      allowedTCPPorts = mkOption {
        type = types.listOf types.int;
        default = [ ];
        description = ''
          Allowed TCP ports. This is overridden by `allowAll`.
        '';
      };
      allowedUDPPorts = mkOption {
        type = types.listOf types.int;
        default = [ ];
        description = ''
          Allowed UDP ports. This is overridden by `allowAll`.
        '';

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
      policy = mkOption {
        type = types.attrsOf (types.submodule policyType);
        default = { };
        description = ''
          The firewall policy of this network.
        '';
      };
      includeRoutesTo = mkOption {
        internal = true;
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
      # TODO(jared): Calculate these in this submodule's config.
      ipv4Cidr = mkOption { internal = true; type = types.int; default = 24; };
      ipv6Cidr = mkOption { internal = true; type = types.int; default = 64; };
      networkIPv4 = mkOption { internal = true; type = types.str; };
      networkIPv4Cidr = mkOption { internal = true; type = types.str; };
      networkIPv4SignificantBits = mkOption { internal = true; type = types.str; };
      networkGuaCidr = mkOption { internal = true; type = types.str; };
      networkGuaPrefix = mkOption { internal = true; type = types.str; };
      networkUlaCidr = mkOption { internal = true; type = types.str; };
      networkUlaPrefix = mkOption { internal = true; type = types.str; };
    };

    config = {
      includeRoutesTo = map
        (network: network.name)
        (lib.filter
          (network: (
            (config.name != network.name)
            && (lib.attrByPath [ config.name "includeRouteTo" ] false network.policy)
          ))
          (builtins.attrValues cfg.networks));
    };
  };
in
{
  # duplicate `networking.firewall` options to be under nftables and
  # implemented in this module.
  options.networking.nftables.firewall = lib.filterAttrs (k: _: (filter (e: k == e) [ "interfaces" ]) != [ ]) options.networking.firewall;

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
        config.custom.inventory.networks) == { };
    }];

    environment.etc."inventory.json".source = (pkgs.formats.json { }).generate
      "inventory.json"
      config.custom.inventory;
  };
}
