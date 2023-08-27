{ config, lib, pkgs, ... }:
let
  cfg = config.custom.wg-mesh;

  matchIPv4 = builtins.match "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+";
  isIPv6 = ip: (matchIPv4 ip) == null;

  inventory = import ./inventory.nix;
  host = inventory."${cfg.name}";

  deviceUnit = "sys-subsystem-net-devices-wg0.device";

  corednsConfigFile = pkgs.writeText "wg-mesh.Corefile" ''
    internal {
      bind wg0
      hosts {
        ${lib.concatMapStringsSep "\n    " ({ name, ...}: "${inventory.${name}.ip} ${name}.internal") (lib.attrValues cfg.peers) }
      }
    }
  '';

  wgEndpointRefresh = pkgs.writeShellApplication {
    name = "wg-endpoint-refresh";
    runtimeInputs = [ pkgs.dnsutils pkgs.wireguard-tools pkgs.gawk ];
    text = builtins.readFile ./wg-endpoint-refresh.bash;
  };

  wgEndpointRefreshArgs = lib.concatMapStringsSep " "
    ({ name, dnsName, ... }:
      let peer = inventory.${name}; in
      "${peer.publicKey}:${dnsName}")
    (lib.filter
      ({ dnsName, ... }: dnsName != null)
      (lib.attrValues cfg.peers));
in
{
  options.custom.wg-mesh = with lib; {
    enable = mkEnableOption "wireguard mesh network node";
    name = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = mdDoc "The name of the host";
    };
    dns = mkEnableOption "setup DNS for peers of this node";
    peers = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          name = mkOption {
            type = types.str;
            default = name;
            description = mdDoc ''
              The name of the peer.
            '';
          };
          dnsName = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = mdDoc ''
              The DNS name of the peer. This will be used to create a wireguard
              endpoint on this peer. Leave to null if this client does not
              initiate the wireguard tunnel to this peer.
            '';
          };
          extraConfig = mkOption {
            type = types.attrs;
            default = { };
            description = mdDoc ''
              Options that would go under the [WireguardPeer] section in
              systemd.netdev(5).
            '';
          };
        };
      }));
      default = { };
      example = ''
        {
          peer1.extraConfig.PersistentKeepalive = 25;
        }
      '';
      description = mdDoc ''
        Peers of this wg node
      '';
    };
    firewall = {
      trustedIPs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          IPs for which all traffic (input & forward) will be accepted.
        '';
      };
      ips = mkOption {
        type = types.attrsOf (types.submodule ({ name, ... }: {
          options = {
            ip = mkOption {
              type = types.str;
              default = name;
            };
            allowedTCPPorts = mkOption {
              type = types.listOf types.port;
              default = [ ];
            };
            allowedUDPPorts = mkOption {
              type = types.listOf types.port;
              default = [ ];
            };
          };
        }));
        default = { };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.systemd.network.enable;
        message = "systemd-networkd must be enabled";
      }
      {
        assertion = config.services.resolved.enable;
        message = "systemd-resolved must be enabled";
      }
      {
        assertion = config.networking.nftables.enable;
        message = "nftables must be enabled";
      }
    ];

    environment.systemPackages = [ pkgs.wireguard-tools ];

    sops.secrets.wg0 = { mode = "0640"; group = config.users.groups.systemd-network.name; };

    networking.firewall.allowedUDPPorts = [ config.systemd.network.netdevs.wg0.wireguardConfig.ListenPort ];
    systemd.network.netdevs.wg0 = {
      netdevConfig = {
        Name = "wg0";
        Kind = "wireguard";
      };
      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets.wg0.path;
        ListenPort = 51820;
      };
      wireguardPeers = map
        ({ name, dnsName, extraConfig, ... }:
          let
            peer = inventory.${name};
          in
          {
            wireguardPeerConfig = lib.recursiveUpdate extraConfig ({
              AllowedIPs = [ (peer.ip + "/128") ];
              PublicKey = peer.publicKey;
            } // lib.optionalAttrs (dnsName != null) {
              Endpoint = "${dnsName}:51820";
            });
          })
        (lib.attrValues cfg.peers);
    };

    systemd.network.networks.wg0 = {
      name = config.systemd.network.netdevs.wg0.netdevConfig.Name;
      address = [ (host.ip + "/64") ];
      dns = [ "[${host.ip}]:53" ];
      # Use as a routing-only domain
      domains = [ "~internal" ];
      networkConfig = {
        # Only use this link's DNS settings for the configured domain
        DNSDefaultRoute = false;
        # This is private DNS, so DNSSEC does not make sense here
        DNSSEC = false;
      };
    };

    systemd.services.wg-mesh-coredns = lib.mkIf cfg.dns {
      description = "Coredns wg-mesh dns server";
      after = [ deviceUnit ];
      partOf = [ deviceUnit ];
      wantedBy = [ deviceUnit ];
      serviceConfig = {
        PermissionsStartOnly = true;
        LimitNPROC = 512;
        LimitNOFILE = 1048576;
        CapabilityBoundingSet = "cap_net_bind_service";
        AmbientCapabilities = "cap_net_bind_service";
        NoNewPrivileges = true;
        DynamicUser = true;
        ExecStart = "${lib.getBin config.services.coredns.package}/bin/coredns -conf=${corednsConfigFile}";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR1 $MAINPID";
        Restart = "on-failure";
      };
    };

    systemd.services.wg-endpoint-refresh = {
      # don't enable this if there are no endpoints to query
      enable = wgEndpointRefreshArgs != "";
      description = "Endpoint refresh for wireguard peers";
      after = [ deviceUnit ];
      partOf = [ deviceUnit ];
      wantedBy = [ deviceUnit ];
      path = [ pkgs.parallel wgEndpointRefresh ];
      serviceConfig = {
        PermissionsStartOnly = true;
        CapabilityBoundingSet = [ "cap_net_admin" ];
        AmbientCapabilities = [ "cap_net_admin" ];
        DynamicUser = true;
        Restart = "on-failure";
      };
      environment.HOME = "/tmp";
      script = ''
        parallel --ungroup wg-endpoint-refresh ::: "$@"
      '';
      scriptArgs = wgEndpointRefreshArgs;
    };

    # always forward
    networking.firewall.extraForwardRules = (lib.concatMapStrings
      (ip: ''
        ${if isIPv6 ip then "ip6" else "ip"} saddr ${ip} accept
      '')
      cfg.firewall.trustedIPs);

    networking.firewall.extraInputRules = (lib.concatMapStrings
      (ip: ''
        ${if isIPv6 ip then "ip6" else "ip"} saddr ${ip} accept
      '')
      cfg.firewall.trustedIPs)
    +
    (lib.concatMapStrings
      ({ ip, allowedTCPPorts, allowedUDPPorts, ... }: (lib.optionalString (allowedTCPPorts != [ ]) ''
        ${if isIPv6 ip then "ip6" else "ip"} saddr ${ip} tcp dport { ${lib.concatMapStringsSep ", " toString allowedTCPPorts} } accept
      '') + (lib.optionalString (allowedUDPPorts != [ ]) ''
        ${if isIPv6 ip then "ip6" else "ip"} saddr ${ip} udp dport { ${lib.concatMapStringsSep ", " toString allowedUDPPorts} } accept
      ''))
      (lib.attrValues cfg.firewall.ips));

    networking.nat =
      let
        partition = lib.partition isIPv6 cfg.firewall.trustedIPs;
      in
      {
        internalIPv6s = partition.right;
        internalIPs = partition.wrong;
      };
  };
}
