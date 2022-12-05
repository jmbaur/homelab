# TODO(jared): Factor out interface names and make firewall policies a
# configuration option.

{ config, lib, ... }: {
  networking = {
    nat.enable = false;
    firewall.enable = false;
    nftables = {
      enable = true;
      ruleset = with config.systemd.network;
        let
          devWAN = networks.wan.name;
          devWAN6 = networks.hurricane.name;
          v4BogonNetworks = lib.concatMapStringsSep
            ", "
            (route: route.routeConfig.Destination)
            (networks.wan.routes);
          v6BogonNetworks = lib.concatMapStringsSep
            ", "
            (route: route.routeConfig.Destination)
            (networks.hurricane.routes);
          lanIPv4Networks = lib.concatMapStringsSep ", "
            (network: network.networkIPv4Cidr)
            (builtins.attrValues config.custom.inventory.networks);
          wireguardPorts = lib.concatMapStringsSep ", " (netdev: toString netdev.wireguardConfig.ListenPort)
            (builtins.attrValues
              (lib.filterAttrs
                (_: netdev: netdev.netdevConfig.Kind == "wireguard" && netdev.wireguardConfig ? ListenPort)
                config.systemd.network.netdevs));
        in
        (''
          add table inet firewall

          add chain inet firewall input { type filter hook input priority 0; policy drop; }
          add rule inet firewall input ct state vmap { established : accept, related : accept, invalid : drop }
          add rule inet firewall input iifname lo accept

          add chain inet firewall forward { type filter hook forward priority 0; policy drop; }
          add rule inet firewall forward ct state vmap { established : accept, related : accept, invalid : drop }

          add chain inet firewall output { type filter hook output priority 0; policy accept; }
          add rule inet firewall input icmp type { destination-unreachable, echo-request, parameter-problem, time-exceeded } accept
          add rule inet firewall input icmpv6 type { destination-unreachable, echo-request, nd-neighbor-advert, nd-neighbor-solicit, nd-router-solicit, packet-too-big, parameter-problem, time-exceeded } accept

          add table ip nat
          add chain ip nat prerouting { type nat hook prerouting priority 100; policy accept; }
          add chain ip nat postrouting { type nat hook postrouting priority 100; policy accept; }
          add rule ip nat postrouting ip saddr { ${lanIPv4Networks} } oifname ${devWAN} masquerade

          # Always allow input from LAN interfaces to access crucial router IP services
          add rule inet firewall input iifname ne { ${devWAN}, ${devWAN6} } meta l4proto udp th dport { "bootps", "ntp", "dhcpv6-server" } accept
          add rule inet firewall input iifname ne { ${devWAN}, ${devWAN6} } meta l4proto { tcp, udp } th dport "domain" accept

          # Reject traffic from addresses not found on the internet
          add chain inet firewall not_in_internet
          add rule inet firewall not_in_internet iifname { ${devWAN} } ip saddr { ${v4BogonNetworks} } drop
          add rule inet firewall not_in_internet iifname { ${devWAN6} } ip6 saddr { ${v6BogonNetworks} } drop
          add rule inet firewall not_in_internet oifname { ${devWAN} } ip daddr { ${v4BogonNetworks} } drop
          add rule inet firewall not_in_internet oifname { ${devWAN6} } ip6 daddr { ${v6BogonNetworks} } drop
          add rule inet firewall input jump not_in_internet
          add rule inet firewall forward jump not_in_internet
          add rule inet firewall output jump not_in_internet

          # Allow all wireguard traffic
          add rule inet firewall input meta l4proto { udp } th dport { ${wireguardPorts} } accept

          # Allow limited icmp echo requests to wan interfaces
          add rule inet firewall input iifname . icmp type { ${devWAN} . echo-request } limit rate 5/second accept
          add rule inet firewall input iifname . icmpv6 type { ${devWAN6} . echo-request } limit rate 5/second accept

          # Allow icmpv6 echo requests to internal network hosts (needed for
          # proper IPv6 functionality)
          add rule inet firewall forward iifname . icmpv6 type { ${devWAN6} . echo-request } accept
        ''
        +
        # input rules
        (lib.concatStringsSep "\n"
          (lib.flatten
            (lib.mapAttrsToList
              (iface: fw:
                let
                  chain = "input_to_${iface}";
                  rangeToString = range: "${toString range.from}-${toString range.to}";
                  allowedTCPPorts = (map toString fw.allowedTCPPorts) ++ (map rangeToString fw.allowedTCPPortRanges);
                  allowedUDPPorts = (map toString fw.allowedUDPPorts) ++ (map rangeToString fw.allowedUDPPortRanges);
                in
                [
                  "add chain inet firewall ${chain}"
                  "add rule inet firewall ${chain} meta l4proto tcp th dport { ${lib.concatStringsSep ", " allowedTCPPorts} } accept"
                  "add rule inet firewall ${chain} meta l4proto udp th dport { ${lib.concatStringsSep ", " allowedUDPPorts} } accept"
                  "add rule inet firewall input iifname ${iface} jump ${chain}"
                ] config.networking.nftables.firewall.interfaces))))
        +
        # forwarding rules
        (lib.concatStringsSep "\n" (map
          (
            network:
            let
              interface = "${config.systemd.network.networks.${network.name}.name}";
              chainTo = "forward_to_${network.name}";
            in
            ([
              "add rule inet firewall forward iifname . oifname { ${interface} . ${devWAN}, ${interface} . ${devWAN6} } accept" # allow the network to access the internet
              "add chain inet firewall ${chainTo}" # chain that filters traffic forwarding TO the target network
              "add rule inet firewall forward oifname ${interface} jump ${chainTo}" # add the prior chain to the forward chain
            ] ++
            (lib.flatten
              (lib.mapAttrsToList
                (policyName: policy:
                  let
                    nftPrefix = "add rule inet firewall ${chainTo}";
                    policyNetwork = config.custom.inventory.networks.${policyName};
                    iifname = "${config.systemd.network.networks.${policyNetwork.name}.name}";
                  in
                  (
                    (lib.optional
                      (policy.allowedTCPPorts != [ ]) "${nftPrefix} meta l4proto tcp th dport { ${lib.concatMapStringsSep ", " toString policy.allowedTCPPorts} } accept")
                    ++
                    (lib.optional
                      (policy.allowedUDPPorts != [ ]) "${nftPrefix} meta l4proto udp th dport { ${lib.concatMapStringsSep ", " toString policy.allowedUDPPorts} } accept")
                    ++
                    (lib.optional
                      (policy.allowAll) "${nftPrefix} iifname ${iifname} oifname ${interface} accept")
                  )
                )
                (network.policy))))
          )
          (builtins.attrValues config.custom.inventory.networks))));
    };
  };
}
