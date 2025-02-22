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
      Allowed TCP ports from this peer
    '';
  };

  allowedUDPPortsOption = mkOption {
    type = types.listOf types.ints.positive;
    default = [ ];
    description = ''
      Allowed UDP ports from this peer
    '';
  };

  peerSubmodule =
    { ... }:
    {
      options = {
        ip = mkOption { type = types.nonEmptyStr; };

        allowAll = mkEnableOption "allow all traffic from this peer";

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
      type = types.attrsOf (types.submodule peerSubmodule);
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
        mapAttrsToList (peerName: peerSettings: ''
          ${peerSettings.ip} ${peerName}.internal
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
          peerName: peerSettings:
          if peerSettings.allowAll then
            ''ip6 saddr ${peerSettings.ip} accept comment "accept all traffic from ${peerName}"''
          else
            optionalString (peerSettings.allowedTCPPorts != [ ])
              ''ip6 saddr ${peerSettings.ip} tcp dport { ${
                concatMapStringsSep ", " toString peerSettings.allowedTCPPorts
              } } accept comment "accepted TCP ports from ${peerName}"''
            +
              optionalString (peerSettings.allowedUDPPorts != [ ])
                ''ip6 saddr ${peerSettings.ip} udp dport { ${
                  concatMapStringsSep ", " toString peerSettings.allowedUDPPorts
                } } accept comment "accepted UDP ports from ${peerName}"''
        ) cfg.peers)
        ++ [
          (
            let
              ips = concatMapStringsSep ", " (peer: peer.ip) (attrValues cfg.peers);
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
