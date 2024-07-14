{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.wgNetwork;

  wgListenPort = config.systemd.network.netdevs."10-wg-network".wireguardConfig.ListenPort;

  firewallRule =
    {
      name,
      ip6addr ? null,
      iifname ? null,
      l4proto,
      ports,
    }:
    let
      filters =
        lib.optionals (ip6addr != null) [ "ip6 saddr ${ip6addr}" ]
        ++ lib.optionals (iifname != null) [ "iifname ${iifname}" ]
        ++ [ "${l4proto} dport { ${lib.concatMapStringsSep ", " toString ports} }" ];
    in
    lib.optionalString (ports != [ ]) ''
      ${toString filters} accept comment "allow from ${name}"
    '';

  peeredNodes = lib.filterAttrs (_: { enable, ... }: enable) cfg.nodes;

  babelEnabled = lib.length (lib.attrNames peeredNodes) > 1;

  ulaNetworkSegments =
    map (hextet: lib.toLower (lib.toHexString hextet)) cfg.ulaHextets
    ++ lib.genList (_: "0000") (4 - (lib.length cfg.ulaHextets));

  ulaNetwork = "${lib.concatStringsSep ":" ulaNetworkSegments}::/64";

  babeldPort = 6696;
in
{
  options.custom.wgNetwork = with lib; {
    isEnabled = mkOption {
      type = types.bool;
      internal = true;
      default = false;
    };

    ulaHextets = mkOption {
      type = types.listOf types.ints.positive;
      example = [
        64789
        49711
        54517
      ];
    };

    wgInterface = mkOption {
      type = types.str;
      default = "wg0";
    };

    privateKey = mkOption {
      type = types.attrTag {
        value = mkOption { type = types.str; };
        file = mkOption { type = types.path; };
      };
    };

    nodes = mkOption {
      default = { };
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          let
            hash = (builtins.hashString "sha256" name);
            genHextetOffset = lib.genList (x: x * 4);
            ulaHostSegments = map (x: lib.substring x 4 hash) (genHextetOffset 4);
            linkLocalNetworkSegments = [ "fe80" ] ++ lib.genList (_: "0000") 3;
            linkLocalHostSegments = map (x: lib.substring x 4 hash) (genHextetOffset 4);
          in
          {
            options = {
              enable = mkEnableOption "wg peer ${node}";

              allowedTCPPorts = mkOption {
                type = types.listOf types.ints.positive;
                default = [ ];
              };

              allowedUDPPorts = mkOption {
                type = types.listOf types.ints.positive;
                default = [ ];
              };

              ip6addr = mkOption {
                internal = true;
                readOnly = true;
                type = types.str;
              };

              ip6lladdr = mkOption {
                internal = true;
                readOnly = true;
                type = types.str;
              };

              pubkey = mkOption {
                internal = true;
                readOnly = true;
                type = types.str;
              };

              hostname = mkOption { type = types.str; };
            };

            config = {
              ip6addr = lib.concatStringsSep ":" (ulaNetworkSegments ++ ulaHostSegments);
              ip6lladdr = lib.concatStringsSep ":" (linkLocalNetworkSegments ++ linkLocalHostSegments);
            };
          }
        )
      );
    };
  };

  config = lib.mkIf (peeredNodes != { }) {
    custom.wgNetwork.isEnabled = true;

    assertions = [
      {
        assertion = config.systemd.network.enable;
        message = "systemd-networkd must be enabled to use wg-network";
      }
      {
        assertion = config.networking.nftables.enable;
        message = "nftables must be enabled to use wg-network";
      }
      {
        assertion = !cfg.nodes.${config.networking.hostName}.enable;
        message = "host cannot have a wg peer with itself";
      }
      {
        # TODO(jared): this is an arbitrary limitation?
        assertion = lib.length cfg.ulaHextets >= 1 && lib.length cfg.ulaHextets <= 4;
        message = "ULA network prefix must have at least 1 and at most than 4 hextets ";
      }
    ];

    environment.systemPackages = [ pkgs.wireguard-tools ];

    networking.firewall.extraInputRules = lib.concatLines (
      lib.flatten (
        lib.mapAttrsToList (node: nodeConfig: [
          (firewallRule {
            name = node;
            ip6addr = nodeConfig.ip6addr;
            l4proto = "tcp";
            ports = nodeConfig.allowedTCPPorts;
          })
          (firewallRule {
            name = node;
            ip6addr = nodeConfig.ip6addr;
            l4proto = "udp";
            ports = nodeConfig.allowedUDPPorts;
          })
          (firewallRule {
            name = node;
            l4proto = "udp";
            iifname = cfg.wgInterface;
            ports = [ babeldPort ];
          })
        ]) cfg.nodes
      )
    );

    networking.firewall.allowedUDPPorts = [ wgListenPort ];

    systemd.network.netdevs."10-wg-network" = {
      netdevConfig = {
        Name = cfg.wgInterface;
        Kind = "wireguard";
      };
      wireguardConfig = lib.mkMerge [
        {
          ListenPort = 51820;
          RouteTable = lib.mkIf babelEnabled "off";
        }
        (lib.mkIf (cfg.privateKey ? file) { PrivateKeyFile = cfg.privateKey.file; })
        (lib.mkIf (cfg.privateKey ? value) {
          PrivateKey = lib.warn "Insecure wireguard private key set in nixos config, this value will be in /nix/store" cfg.privateKey.value;
        })
      ];
      wireguardPeers = lib.mapAttrsToList (_: nodeConfig: {
        AllowedIPs = [
          "${nodeConfig.ip6addr}/128"
          "fe80::/64"
          "ff02::1:6/128"
        ];
        PublicKey = nodeConfig.pubkey;

        # Keep stateful firewall's connection tracking alive. 25 seconds should
        # work with most firewalls.
        PersistentKeepalive = 25;

        # TODO(jared): Not all nodes are necessarily directly available via
        # hostname (e.g. behind NAT). We shouldn't assume that a node initates
        # a connection to all of its peers.
        Endpoint = "${nodeConfig.hostname}:${toString wgListenPort}";
      }) peeredNodes;
    };

    systemd.network.networks."10-wg-network" = {
      name = cfg.wgInterface;
      routes = lib.optionals babelEnabled (
        lib.mapAttrsToList (_: nodeConfig: { Destination = "${nodeConfig.ip6addr}/128"; }) peeredNodes
      );
      addresses = [
        {
          Address = "${cfg.nodes.${config.networking.hostName}.ip6addr}/64";
          AddPrefixRoute = !babelEnabled;
        }
        { Address = "${cfg.nodes.${config.networking.hostName}.ip6lladdr}/64"; }
      ];
    };

    networking.extraHosts = lib.concatLines (
      lib.mapAttrsToList (node: nodeConfig: "${nodeConfig.ip6addr} ${node}.internal") cfg.nodes
    );

    services.babeld = {
      enable = babelEnabled;
      interfaces.${cfg.wgInterface}.type = "tunnel";
      extraConfig = ''
        local-port 33123

        random-id true
        link-detect true

        import-table 254 # main
        export-table 254 # main

        # in ip ${ulaNetwork} eq 128 allow
        in allow

        # redistribute ip ${ulaNetwork} eq 128 allow
        # redistribute local deny
        redistribute local allow
      '';
    };
  };
}
