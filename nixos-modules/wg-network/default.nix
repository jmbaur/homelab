{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    attrNames
    concatLines
    concatMapStringsSep
    concatStringsSep
    elemAt
    filterAttrs
    flatten
    genList
    length
    mapAttrs'
    mapAttrsToList
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalString
    optionals
    options
    substring
    toHexString
    toLower
    types
    ;

  cfg = config.custom.wgNetwork;

  inherit (config.networking) hostName;

  inputFirewallRule =
    {
      ip6addr ? null,
      iifname ? null,
      l4proto,
      ports,
    }:
    let
      filters =
        optionals (ip6addr != null) [ "ip6 saddr ${ip6addr}" ]
        ++ optionals (iifname != null) [ "iifname ${iifname}" ]
        ++ [ "${l4proto} dport { ${concatMapStringsSep ", " toString ports} }" ];
    in
    optionalString (ports != [ ]) ''
      ${toString filters} accept
    '';

  peeredNodes = filterAttrs (_: { peer, ... }: peer) cfg.nodes;

  firstPeeredNode = elemAt (attrNames peeredNodes) 0;

  hextetOffsets = genList (x: x * 4) 4;

  linkLocalNetworkSegments = [ "fe80" ] ++ genList (_: "0000") 3;

  ulaNetworkSegments =
    map (hextet: toLower (toHexString hextet)) cfg.ulaHextets
    ++ genList (_: "0000") (4 - (length cfg.ulaHextets));

  ulaNetwork = "${concatStringsSep ":" ulaNetworkSegments}::/64";

  babeldPort = 6696;

  wgPort = 51820;

  wireguardNetdevs = filterAttrs (
    _: netdev: netdev.netdevConfig.Kind == "wireguard"
  ) config.systemd.network.netdevs;

in
{
  options.custom.wgNetwork = {
    ulaHextets = mkOption {
      type = (types.nonEmptyListOf types.ints.positive) // {
        # It doesn't make sense to allow for merging various values across
        # modules, as the ordering of the hextets are important and they should
        # all be defined in a single module.
        merge = options.mergeEqualOption;
      };
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
            hostSegments = map (x: substring x 4 hostHash) hextetOffsets;
            hostPeerHash = builtins.hashString "sha256" (hostName + name);
            hostPeerSegments = map (x: substring x 4 hostPeerHash) hextetOffsets;
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
              ulaAddr = concatStringsSep ":" (ulaNetworkSegments ++ hostSegments);
              linkLocalAddr = concatStringsSep ":" (linkLocalNetworkSegments ++ hostPeerSegments);
            };
          }
        )
      );
    };
  };

  config = mkIf (peeredNodes != { }) {
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
        assertion = length cfg.ulaHextets >= 1 && length cfg.ulaHextets <= 4;
        message = "ULA network prefix must have at least 1 and at most than 4 hextets ";
      }
      {
        assertion =
          length (attrNames (filterAttrs (_: netdev: netdev.wireguardConfig ? ListenPort) wireguardNetdevs))
          < 2;
        message = "duplicate ListenPorts configured";
      }
    ];

    environment.systemPackages = [ pkgs.wireguard-tools ];

    # Allow forwarding for any peers in the network.
    networking.firewall.filterForward = true;
    networking.firewall.extraForwardRules = ''
      ip6 saddr ${ulaNetwork} accept
    '';

    networking.firewall.extraInputRules = concatLines (
      [
        (inputFirewallRule {
          l4proto = "tcp";
          ip6addr = ulaNetwork;
          ports = cfg.allowedTCPPorts;
        })
        (inputFirewallRule {
          l4proto = "udp";
          ip6addr = ulaNetwork;
          ports = cfg.allowedUDPPorts;
        })
      ]
      ++ flatten (
        mapAttrsToList (
          name: nodeConfig:
          [
            (inputFirewallRule {
              ip6addr = nodeConfig.ulaAddr;
              l4proto = "tcp";
              ports = nodeConfig.allowedTCPPorts;
            })
            (inputFirewallRule {
              ip6addr = nodeConfig.ulaAddr;
              l4proto = "udp";
              ports = nodeConfig.allowedUDPPorts;
            })
          ]
          ++ optionals nodeConfig.peer [
            (inputFirewallRule {
              l4proto = "udp";
              iifname = "wg-${name}";
              ports = [ babeldPort ];
            })
          ]
        ) cfg.nodes
      )
    );

    networking.firewall.allowedUDPPorts = optionals (
      filterAttrs (_: netdev: netdev.wireguardConfig ? ListenPort) wireguardNetdevs != { }
    ) [ wgPort ];

    systemd.services = mapAttrs' (
      name: nodeConfig:
      let
        interfaceName = config.systemd.network.netdevs."10-wg-${name}".netdevConfig.Name;
      in
      {
        name = "wg-dns@${interfaceName}";
        value = {
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
            "systemd-networkd.service"
          ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Restart = "on-failure";
            RestartSec = 3;
            ExecStart = toString [
              (lib.getExe pkgs.wg-dns)
              interfaceName
              nodeConfig.publicKey
              nodeConfig.endpointHost
            ];
          };
        };
      }
    ) (filterAttrs (_: nodeConfig: nodeConfig.initiate) peeredNodes);

    systemd.network.netdevs = mapAttrs' (name: nodeConfig: {
      name = "10-wg-${name}";
      value = {
        netdevConfig = {
          Name = "wg-${name}";
          Kind = "wireguard";
        };
        wireguardConfig = mkMerge [
          {
            ListenPort = mkIf (!nodeConfig.initiate) wgPort;
            RouteTable = "off";
          }
          (mkIf (nodeConfig.privateKey ? file) { PrivateKeyFile = nodeConfig.privateKey.file; })
          (mkIf (nodeConfig.privateKey ? value) {
            PrivateKey = builtins.warn "Insecure wireguard private key set in nixos config, this value will be in /nix/store" nodeConfig.privateKey.value;
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
            Endpoint = mkIf nodeConfig.initiate "${nodeConfig.endpointHost}:${toString wgPort}";
          }
        ];
      };
    }) peeredNodes;

    systemd.network.networks = mapAttrs' (name: nodeConfig: {
      name = "10-wg-${name}";
      value = {
        name = "wg-${name}";
        linkConfig.Multicast = true;
        routes = [ { Destination = "${nodeConfig.ulaAddr}/128"; } ];
        addresses =
          [ { Address = "${nodeConfig.linkLocalAddr}/64"; } ]
          ++
          # make sure only one unique local address is added on the host
          optionals (name == firstPeeredNode) [
            {
              Address = "${cfg.nodes.${hostName}.ulaAddr}/64";
              AddPrefixRoute = false;
            }
          ];
      };
    }) peeredNodes;

    networking.extraHosts = concatLines (
      mapAttrsToList (node: nodeConfig: "${nodeConfig.ulaAddr} ${node}.internal") cfg.nodes
    );

    services.babeld = {
      enable = true;

      interfaces = mapAttrs' (name: _: {
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
