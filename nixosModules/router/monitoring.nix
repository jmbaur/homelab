{ config, lib, pkgs, ... }: {
  services.journald.enableHttpGateway = true;
  services.prometheus.exporters = {
    blackbox = {
      enable = false;
      configFile = toString ((pkgs.formats.yaml { }).generate "blackbox-config" {
        modules = {
          icmpv6_connectivity = {
            prober = "icmp";
            timeout = "5s";
            icmp = {
              preferred_ip_protocol = "ip6";
              ip_protocol_fallback = false;
            };
          };
          icmpv4_connectivity = {
            prober = "icmp";
            timeout = "5s";
            icmp = {
              preferred_ip_protocol = "ip4";
              ip_protocol_fallback = false;
            };
          };
        };
      });
    };
    node = {
      enable = true;
      enabledCollectors = [ "ethtool" "network_route" "systemd" ];
    };
    wireguard =
      let
        # NOTE: this derivation does not do any actual configuration for
        # wireguard. It just contains peer information so that friendly names
        # can be picked up by the exporter
        stubWireguardConfig = pkgs.writeText "stub-wireguard-config" (lib.concatMapStringsSep "\n"
          (peer: ''
            [Peer]
            # friendly_name = ${peer.name}
            PublicKey = ${peer.publicKey}
            AllowedIPs = ${peer._computed._ipv4},${peer._computed._ipv6.ula}
          '')
          (lib.flatten (
            lib.mapAttrsToList
              (_: network: builtins.attrValues
                (lib.filterAttrs
                  (name: _: name != "_router")
                  network.hosts))
              (lib.filterAttrs
                (_: network: network.wireguard.enable)
                config.router.inventory.networks)
          ))
        );
      in
      {
        enable = true;
        wireguardConfig = stubWireguardConfig;
      };
    kea = {
      enable = true;
      controlSocketPaths = [
        config.services.kea.dhcp4.settings.control-socket.socket-name
        config.services.kea.dhcp6.settings.control-socket.socket-name
      ];
    };
  };
}
