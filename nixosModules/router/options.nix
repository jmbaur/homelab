{ options, config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom.inventory;

  hostType = { name, config, networkConfig, ... }: {
    options = {
      id = mkOption { type = types.int; };
      name = mkOption { type = types.str; default = name; };
      dhcp = mkEnableOption "dhcp-enabled host";
      mac = mkOption { type = types.nullOr types.str; default = null; };
      publicKey = mkOption { type = types.nullOr types.str; default = null; };
      _computed = {
        _ipv4 = mkOption { internal = true; type = types.str; };
        _ipv6.gua = mkOption { internal = true; type = types.str; };
        _ipv6.ula = mkOption { internal = true; type = types.str; };
      };
    };
    # TODO(jared): these calculations make assumptions of the network size
    config._computed = {
      _ipv4 = "${networkConfig._computed._networkIPv4SignificantBits}.${toString config.id}";
      _ipv6.gua = "${networkConfig._computed._networkGuaSignificantBits}::${lib.toLower (lib.toHexString config.id)}";
      _ipv6.ula = "${networkConfig._computed._networkUlaSignificantBits}::${lib.toLower (lib.toHexString config.id)}";
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
      id = mkOption { type = types.int; };
      v4Prefix = mkOption { type = types.str; };
      guaPrefix = mkOption { type = types.str; };
      ulaPrefix = mkOption { type = types.str; };
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
        type = types.attrsOf (types.submoduleWith {
          modules = [ hostType ];
          specialArgs.networkConfig = config;
        });
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
      mtu = mkOption { type = types.nullOr types.int; default = null; };
      _computed = {
        _ipv4Cidr = mkOption { internal = true; type = types.int; };
        _ipv6GuaCidr = mkOption { internal = true; type = types.int; };
        _ipv6UlaCidr = mkOption { internal = true; type = types.int; };
        _networkIPv4 = mkOption { internal = true; type = types.str; };
        _networkIPv4Cidr = mkOption { internal = true; type = types.str; };
        _networkIPv4SignificantBits = mkOption { internal = true; type = types.str; };
        _networkGuaCidr = mkOption { internal = true; type = types.str; };
        _networkGuaSignificantBits = mkOption { internal = true; type = types.str; };
        _networkUlaCidr = mkOption { internal = true; type = types.str; };
        _networkUlaSignificantBits = mkOption { internal = true; type = types.str; };
      };
    };

    config =
      let
        netdump = pkgs.buildGoModule {
          name = "netdump";
          src = ./netdump;
          vendorSha256 = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
        };
        netdumpResult = pkgs.runCommand "netdump-${name}.json" { } ''
          ${netdump}/bin/netdump \
            -v4-prefix=${config.v4Prefix} \
            -gua-prefix=${config.guaPrefix} \
            -ula-prefix=${config.ulaPrefix} > $out
        '';
      in
      {
        _computed = lib.importJSON netdumpResult;
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

  options.custom.inventory.networks = mkOption {
    type = types.attrsOf (types.submodule networkType);
    default = { };
    description = ''
      The networks to be configured by the router.
    '';
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
