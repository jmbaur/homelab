{ options, config, lib, pkgs, ... }:
let

  cfg = config.router.inventory;

  routerHostName = config.networking.hostName;

  netdump = pkgs.buildGoModule {
    name = "netdump";
    src = ./netdump;
    vendorSha256 = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
  };

  hostType = { name, config, networkConfig, ... }: {
    options = with lib; {
      id = mkOption { type = types.int; };
      name = mkOption { type = types.str; default = name; };
      dhcp = mkEnableOption "dhcp-enabled host";
      mac = mkOption { type = types.nullOr types.str; default = null; };
      publicKey = mkOption { type = types.nullOr types.str; default = null; };
      privateKeyPath = mkOption { type = types.nullOr types.path; default = null; };
      _computed = {
        _ipv4 = mkOption { internal = true; type = types.str; };
        _ipv4Cidr = mkOption { internal = true; type = types.str; };
        _ipv6.gua = mkOption { internal = true; type = types.str; };
        _ipv6.guaCidr = mkOption { internal = true; type = types.str; };
        _ipv6.ula = mkOption { internal = true; type = types.str; };
        _ipv6.ulaCidr = mkOption { internal = true; type = types.str; };
      };
    };
    config = {
      _computed = lib.importJSON (pkgs.runCommand "hostdump-${name}.json" { } ''
        ${netdump}/bin/netdump \
          -host \
          -id=${toString config.id} \
          -v4-prefix=${networkConfig._computed._v4Prefix} \
          -gua-prefix=${networkConfig._computed._v6GuaPrefix} \
          -ula-prefix=${networkConfig._computed._v6UlaPrefix} > $out
      '');
    };
  };

  policyType = { name, config, ... }: {
    options = with lib; {
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
    options = with lib; {
      name = mkOption {
        type = types.str;
        default = name;
        description = ''
          The name of the network.
        '';
      };
      id = mkOption { type = types.int; };
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
        privateKeyPath = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = ''
            The path to the private key of the router for this network.
          '';
        };
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
        _networkIPv4SignificantOctets = mkOption { internal = true; type = types.str; };
        _dhcpv4Pool = mkOption { internal = true; type = types.str; };
        _networkGuaCidr = mkOption { internal = true; type = types.str; };
        _networkUlaCidr = mkOption { internal = true; type = types.str; };
        _dhcpv6Pool = mkOption { internal = true; type = types.str; };
        _v4Prefix = mkOption { internal = true; type = types.str; default = config._computed._networkIPv4Cidr; };
        _v6GuaPrefix = mkOption { internal = true; type = types.str; default = config._computed._networkGuaCidr; };
        _v6UlaPrefix = mkOption { internal = true; type = types.str; default = config._computed._networkUlaCidr; };
      };
    };

    config = {
      _computed = lib.importJSON (pkgs.runCommand "netdump-${name}.json" { } ''
        ${netdump}/bin/netdump \
          -network \
          -id=${toString config.id} \
          -v4-prefix=${cfg.v4Prefix} \
          -gua-prefix=${cfg.v6GuaPrefix} \
          -ula-prefix=${cfg.v6UlaPrefix} > $out
      '');
      hosts._router = { id = 1; name = routerHostName; };
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
  options.networking.nftables.firewall = lib.filterAttrs (k: _: (lib.filter (e: k == e) [ "interfaces" ]) != [ ]) options.networking.firewall;

  options.router.inventory = with lib; {
    wan = mkOption {
      type = types.str;
      description = ''
        The name of the WAN interface.
      '';
    };
    v4Prefix = mkOption { type = types.str; };
    v6GuaPrefix = mkOption { type = types.str; };
    v6UlaPrefix = mkOption { type = types.str; };
    networks = mkOption {
      type = types.attrsOf (types.submodule networkType);
      default = { };
      description = ''
        The networks to be configured by the router.
      '';
    };
  };

  config = lib.mkIf (config.router.inventory != { }) {
    assertions = [
      {
        message = "Cannot have physical.enable and wireguard.enable set for the same network";
        assertion = (lib.filterAttrs
          (_: network: network.physical.enable && network.wireguard.enable)
          config.router.inventory.networks) == { };
      }
      (
        let
          ips = lib.flatten
            (map (network:
              (map
                (host:
                  with host._computed; [ _ipv4 _ipv6.gua _ipv6.ula ])
                (builtins.attrValues network.hosts))
                (builtins.attrValues config.router.inventory.networks)));
        in
        {
          assertion = lib.length ips == lib.length (lib.unique ips);
          message = "Duplicate IP addresses found";
        }
      )
    ];

    environment.etc."inventory.json".source = (pkgs.formats.json { }).generate
      "inventory.json"
      config.router.inventory;
  };
}
