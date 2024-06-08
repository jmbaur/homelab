{ config, lib, ... }:

let
  cfg = config.custom.wgNetwork;

  wgListenPort = config.systemd.network.netdevs."10-wg-network".wireguardConfig.ListenPort;

  allPossibleNodes =
    lib.mapAttrs
      (node: pubkey: {
        inherit pubkey;

        # NOTE: This is dependent on perspective of the peer initiating the
        # connection. We default to the scenario where peers are on the same
        # LAN and can communicate via mDNS, however this can be modified with
        # the per-node `hostname` NixOS option.
        hostname = "${node}.local";

        ip6addr =
          let
            hash = (builtins.hashString "sha256" node);
            networkSegments = [
              "fd0b"
              "e072"
              "d598"
            ]; # randomly generated
            hostSegments = map (x: builtins.substring x 4 hash) (builtins.genList (x: x * 4) 5);
          in
          (lib.concatStringsSep ":" (networkSegments ++ hostSegments));
      })
      {
        celery = "ictBEFKAIAkf7Rw43pVZuSTRw6ihV0wu5//Hr4cdU18=";
        potato = "9jbT3pl/AokDRBpwMALhC8cPfFL3amNfd1bTcZgoLDA=";
      };

  firewallRule = name: ip6addr: l4proto: port: ''
    ip6 saddr { ${ip6addr} } ${l4proto} dport ${toString port} accept comment "allow from ${name}"
  '';

  enabledNodes = lib.filterAttrs (_: { enable, ... }: enable) cfg.nodes;
in
{
  options.custom.wgNetwork = with lib; {

    wgInterface = mkOption {
      type = types.str;
      default = "wg0";
    };

    nodes = lib.mapAttrs (node: nodeConfig: {
      enable = mkEnableOption "wg node ${node}";

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
        default = nodeConfig.ip6addr;
      };

      pubkey = mkOption {
        internal = true;
        readOnly = true;
        default = nodeConfig.pubkey;
      };

      hostname = mkOption { default = nodeConfig.hostname; };
    }) allPossibleNodes;
  };

  config = lib.mkIf (enabledNodes != { }) {
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
    ];

    networking.firewall.extraInputRules = lib.concatLines (
      lib.flatten (
        lib.mapAttrsToList (
          node: nodeConfig:
          (map (firewallRule node nodeConfig.ip6addr "tcp") nodeConfig.allowedTCPPorts)
          ++ (map (firewallRule node nodeConfig.ip6addr "udp") nodeConfig.allowedUDPPorts)
        ) enabledNodes
      )
    );

    networking.firewall.allowedUDPPorts = [ wgListenPort ];

    sops.secrets.wg = {
      mode = "0640";
      owner = "root";
      group = "systemd-networkd";
    };

    systemd.network.netdevs."10-wg-network" = {
      netdevConfig = {
        Name = cfg.wgInterface;
        Kind = "wireguard";
      };
      wireguardConfig = {
        ListenPort = 51820;
        PrivateKeyFile = config.sops.secrets.wg.path;
      };
      wireguardPeers = lib.mapAttrsToList (_: nodeConfig: {
        AllowedIPs = "${nodeConfig.ip6addr}/128";
        PublicKey = nodeConfig.pubkey;

        # Keep stateful firewall's connection tracking alive. 25 seconds should
        # work with most firewalls.
        PersistentKeepalive = 25;

        # TODO(jared): Not all nodes are necessarily directly available via
        # hostname (e.g. behind NAT). We shouldn't assume that a node initates
        # a connection to all of its peers.
        Endpoint = "${nodeConfig.hostname}:${toString wgListenPort}";
      }) enabledNodes;
    };

    systemd.network.networks."10-wg-network" = {
      name = cfg.wgInterface;
      address = [ "${cfg.nodes.${config.networking.hostName}.ip6addr}/48" ];
    };

    networking.extraHosts = lib.concatLines (
      lib.mapAttrsToList (node: nodeConfig: "${nodeConfig.ip6addr} ${node}.internal") enabledNodes
    );
  };
}
