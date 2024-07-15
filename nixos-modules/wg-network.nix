{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.wgNetwork;

  inherit (config.networking) hostName;

  firewallRule =
    {
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
      ${toString filters} accept
    '';

  peeredNodes = lib.filterAttrs (_: { peer, ... }: peer) cfg.nodes;

  firstPeeredNode = lib.elemAt (lib.attrNames peeredNodes) 0;

  hextetOffsets = lib.genList (x: x * 4) 4;

  linkLocalNetworkSegments = [ "fe80" ] ++ lib.genList (_: "0000") 3;

  ulaNetworkSegments =
    map (hextet: lib.toLower (lib.toHexString hextet)) cfg.ulaHextets
    ++ lib.genList (_: "0000") (4 - (lib.length cfg.ulaHextets));

  ulaNetwork = "${lib.concatStringsSep ":" ulaNetworkSegments}::/64";

  babeldPort = 6696;

  wgPort = 51820;

  wireguardNetdevs = lib.filterAttrs (
    _: netdev: netdev.netdevConfig.Kind == "wireguard"
  ) config.systemd.network.netdevs;
in
{
  options.custom.wgNetwork = with lib; {
    ulaHextets = mkOption {
      type = types.listOf types.ints.positive;
      example = [
        64789
        49711
        54517
      ];
    };

    allowedTCPPorts = mkOption {
      type = types.listOf types.ints.positive;
      default = [ ];
      description = ''
        Allowed TCP ports for the entire overlay network to the host.
      '';
    };

    allowedUDPPorts = mkOption {
      type = types.listOf types.ints.positive;
      default = [ ];
      description = ''
        Allowed UDP ports for the entire overlay network to the host.
      '';
    };

    nodes = mkOption {
      default = { };
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          let
            hostHash = builtins.hashString "sha256" name;
            hostSegments = map (x: lib.substring x 4 hostHash) hextetOffsets;
            hostPeerHash = builtins.hashString "sha256" (hostName + name);
            hostPeerSegments = map (x: lib.substring x 4 hostPeerHash) hextetOffsets;
          in
          {
            options = {
              peer = mkEnableOption "p2p wireguard peer";

              initiate = mkEnableOption "initiate the peer connection";

              allowedTCPPorts = mkOption {
                type = types.listOf types.ints.positive;
                default = [ ];
                description = ''
                  Allowed TCP ports for this node to the host.
                '';
              };

              allowedUDPPorts = mkOption {
                type = types.listOf types.ints.positive;
                default = [ ];
                description = ''
                  Allowed UDP ports for this node to the host.
                '';
              };

              ulaAddr = mkOption {
                internal = true;
                readOnly = true;
                type = types.str;
              };

              linkLocalAddr = mkOption {
                internal = true;
                readOnly = true;
                type = types.str;
              };

              publicKey = mkOption {
                internal = true;
                readOnly = true;
                type = types.str;
                description = ''
                  The public wireguard key of this node for the host.
                '';
              };

              privateKey = mkOption {
                type = types.attrTag {
                  value = mkOption { type = types.str; };
                  file = mkOption { type = types.path; };
                };
                description = ''
                  The private key of the host to for this node.
                '';
              };

              endpointHost = mkOption {
                type = types.str;
                description = ''
                  The host portion of the endpoint address for this node.
                '';
              };
            };

            config = {
              ulaAddr = lib.concatStringsSep ":" (ulaNetworkSegments ++ hostSegments);
              linkLocalAddr = lib.concatStringsSep ":" (linkLocalNetworkSegments ++ hostPeerSegments);
            };
          }
        )
      );
    };
  };

  config = lib.mkIf (peeredNodes != { }) {
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
        assertion = !cfg.nodes.${config.networking.hostName}.peer;
        message = "host cannot have a wg peer with itself";
      }
      {
        # TODO(jared): this is an arbitrary limitation?
        assertion = lib.length cfg.ulaHextets >= 1 && lib.length cfg.ulaHextets <= 4;
        message = "ULA network prefix must have at least 1 and at most than 4 hextets ";
      }
      {
        assertion =
          lib.length (
            lib.attrNames (lib.filterAttrs (_: netdev: netdev.wireguardConfig ? ListenPort) wireguardNetdevs)
          ) < 2;
        message = "duplicate ListenPorts configured";
      }
    ];

    environment.systemPackages = [ pkgs.wireguard-tools ];

    networking.firewall.extraInputRules = lib.concatLines (
      [
        (firewallRule {
          l4proto = "tcp";
          ip6addr = ulaNetwork;
          ports = cfg.allowedTCPPorts;
        })
        (firewallRule {
          l4proto = "udp";
          ip6addr = ulaNetwork;
          ports = cfg.allowedUDPPorts;
        })
      ]
      ++ lib.flatten (
        lib.mapAttrsToList (
          name: nodeConfig:
          [
            (firewallRule {
              ip6addr = nodeConfig.ulaAddr;
              l4proto = "tcp";
              ports = nodeConfig.allowedTCPPorts;
            })
            (firewallRule {
              ip6addr = nodeConfig.ulaAddr;
              l4proto = "udp";
              ports = nodeConfig.allowedUDPPorts;
            })
          ]
          ++ lib.optionals nodeConfig.peer [
            (firewallRule {
              l4proto = "udp";
              iifname = "wg-${name}";
              ports = [ babeldPort ];
            })
          ]
        ) cfg.nodes
      )
    );

    networking.firewall.allowedUDPPorts = lib.optionals (
      lib.filterAttrs (_: netdev: netdev.wireguardConfig ? ListenPort) wireguardNetdevs != { }
    ) [ wgPort ];

    systemd.network.netdevs = lib.mapAttrs' (name: nodeConfig: {
      name = "10-wg-${name}";
      value = {
        netdevConfig = {
          Name = "wg-${name}";
          Kind = "wireguard";
        };
        wireguardConfig = lib.mkMerge [
          {
            ListenPort = lib.mkIf (!nodeConfig.initiate) wgPort;
            RouteTable = "off";
          }
          (lib.mkIf (nodeConfig.privateKey ? file) { PrivateKeyFile = nodeConfig.privateKey.file; })
          (lib.mkIf (nodeConfig.privateKey ? value) {
            PrivateKey = lib.warn "Insecure wireguard private key set in nixos config, this value will be in /nix/store" nodeConfig.privateKey.value;
          })
        ];
        wireguardPeers = [
          {
            AllowedIPs = [ "::/0" ];
            PublicKey = nodeConfig.publicKey;

            # Keep stateful firewall's connection tracking alive. 25 seconds should
            # work with most firewalls.
            PersistentKeepalive = 25;

            # TODO(jared): Not all nodes are necessarily directly available via
            # hostname (e.g. behind NAT). We shouldn't assume that a node initates
            # a connection to all of its peers.
            Endpoint = lib.mkIf nodeConfig.initiate "${nodeConfig.endpointHost}:${toString wgPort}";
          }
        ];
      };
    }) peeredNodes;

    systemd.network.networks = lib.mapAttrs' (name: nodeConfig: {
      name = "10-wg-${name}";
      value = {
        name = "wg-${name}";
        linkConfig.Multicast = true;
        routes = [ { Destination = "${nodeConfig.ulaAddr}/128"; } ];
        addresses =
          [ { Address = "${nodeConfig.linkLocalAddr}/64"; } ]
          ++
          # make sure only one unique local address is added on the host
          lib.optionals (name == firstPeeredNode) [
            {
              Address = "${cfg.nodes.${hostName}.ulaAddr}/64";
              AddPrefixRoute = false;
            }
          ];
      };
    }) peeredNodes;

    networking.extraHosts = lib.concatLines (
      lib.mapAttrsToList (node: nodeConfig: "${nodeConfig.ulaAddr} ${node}.internal") cfg.nodes
    );

    services.babeld = {
      enable = true;

      interfaces = lib.mapAttrs' (name: _: {
        name = "wg-${name}";
        value.type = "tunnel";
      }) peeredNodes;

      extraConfig = ''
        local-port 33123

        random-id true
        link-detect true

        import-table 254 # main
        export-table 254 # main

        in ip ${ulaNetwork} eq 128 allow
        in deny

        redistribute ip ${ulaNetwork} eq 128 allow
        redistribute local deny
      '';
    };
  };
}
