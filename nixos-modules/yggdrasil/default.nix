{ config, lib, ... }:

let
  inherit (lib)
    attrValues
    concatLines
    concatMapStringsSep
    mapAttrsToList
    mkAfter
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalString
    types
    ;

  cfg = config.custom.yggdrasil;

  allowedTCPPortsOption = mkOption {
    type = types.listOf types.ints.positive;
    default = [ ];
    description = ''
      Allowed TCP ports from this node
    '';
  };

  allowedUDPPortsOption = mkOption {
    type = types.listOf types.ints.positive;
    default = [ ];
    description = ''
      Allowed UDP ports from this node
    '';
  };

  nodeSubmodule =
    { ... }:
    {
      options = {
        ip = mkOption { type = types.nonEmptyStr; };

        allowAll = mkEnableOption "allow all traffic from this node";

        allowedTCPPorts = allowedTCPPortsOption;

        allowedUDPPorts = allowedUDPPortsOption;
      };
    };
in
{
  options.custom.yggdrasil = {
    all = {
      allowedTCPPorts = allowedTCPPortsOption;
      allowedUDPPorts = allowedUDPPortsOption;
    };

    allKnownPeers = {
      allowedTCPPorts = allowedTCPPortsOption;
      allowedUDPPorts = allowedUDPPortsOption;
    };

    peers = mkOption {
      type = types.attrsOf (types.submodule nodeSubmodule);
      default = { };
    };
  };

  config = mkIf config.services.yggdrasil.enable (mkMerge [
    {
      # cause ain't nobody wanna write no iptables
      assertions = [
        {
          assertion = config.networking.nftables.enable;
          message = "yggdrasil firewall rules require using nftables";
        }
      ];

      services.yggdrasil.settings.IfName = mkDefault "ygg0";
    }
    (mkIf (cfg.peers != { }) {
      networking.extraHosts = concatLines (
        mapAttrsToList (nodeName: nodeSettings: ''
          ${nodeSettings.ip} ${nodeName}.internal
        '') cfg.peers
      );

      networking.nftables.tables."nixos-fw".content =
        let
          knownPeersTcpPorts = concatMapStringsSep ", " toString cfg.allKnownPeers.allowedTCPPorts;
          knownPeersUdpPorts = concatMapStringsSep ", " toString cfg.allKnownPeers.allowedUDPPorts;
          allPeersTcpPorts = concatMapStringsSep ", " toString cfg.all.allowedTCPPorts;
          allPeersUdpPorts = concatMapStringsSep ", " toString cfg.all.allowedUDPPorts;
        in
        mkAfter ''
          chain yggdrasil-global {
            ${optionalString (
              cfg.allKnownPeers.allowedTCPPorts != [ ]
            ) ''tcp dport { ${knownPeersTcpPorts} } accept''}
            ${optionalString (
              cfg.allKnownPeers.allowedUDPPorts != [ ]
            ) ''udp dport { ${knownPeersUdpPorts} } accept''}
          }

          chain yggdrasil-known-peers {
            ${optionalString (cfg.all.allowedTCPPorts != [ ]) ''tcp dport { ${allPeersTcpPorts} } accept''}
            ${optionalString (cfg.all.allowedUDPPorts != [ ]) ''udp dport { ${allPeersUdpPorts} } accept''}
          }
        '';

      networking.firewall.extraInputRules = concatLines (
        (mapAttrsToList (
          nodeName: nodeSettings:
          if nodeSettings.allowAll then
            ''ip6 saddr ${nodeSettings.ip} accept comment "accept all traffic from ${nodeName}"''
          else
            optionalString (nodeSettings.allowedTCPPorts != [ ])
              ''ip6 saddr ${nodeSettings.ip} tcp dport { ${
                concatMapStringsSep ", " toString nodeSettings.allowedTCPPorts
              } } accept comment "accepted TCP ports from ${nodeName}"''
            +
              optionalString (nodeSettings.allowedUDPPorts != [ ])
                ''ip6 saddr ${nodeSettings.ip} udp dport { ${
                  concatMapStringsSep ", " toString nodeSettings.allowedUDPPorts
                } } accept comment "accepted UDP ports from ${nodeName}"''
        ) cfg.peers)
        ++ [
          (
            let
              ips = concatMapStringsSep ", " (node: node.ip) (attrValues cfg.peers);
            in
            ''
              ${optionalString (ips != [ ]) ''ip6 saddr { ${ips} } goto yggdrasil-known-peers''}
              ip6 saddr 200::/7 goto yggdrasil-global
            ''
          )
        ]
      );
    })
  ]);
}
