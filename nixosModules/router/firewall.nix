# TODO(jared): Factor out interface names and make firewall policys a
# configuration option.

{ config, lib, ... }: {
  networking = {
    nat.enable = false;
    firewall.enable = false;
    nftables = {
      enable = true;
      ruleset = with config.systemd.network;
        let
          toNfVar = str: lib.replaceStrings [ "-" ] [ "_" ] (lib.toUpper str);
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
          # TODO(jared): don't hardcode these
          nfVars = ''
            define DEV_WAN = ${networks.wan.name}
            define DEV_WAN6 = ${networks.hurricane.name}
            define DEV_WG_WWW = ${networks.www.name}
          '' + lib.concatMapStrings
            (network: ''
              define DEV_${toNfVar network.name} = ${config.systemd.network.networks.${network.name}.name}
            '')
            (builtins.attrValues config.custom.inventory.networks);
        in
        ''
          ${nfVars}

          # static configuration

          add table inet firewall
          add chain inet firewall input { type filter hook input priority 0; policy drop; }
          add rule inet firewall input ct state vmap { established : accept, related : accept, invalid : drop }
          add rule inet firewall input iifname lo accept
          add chain inet firewall forward { type filter hook forward priority 0; policy drop; }
          add rule inet firewall forward ct state vmap { established : accept, related : accept, invalid : drop }
          add chain inet firewall output { type filter hook output priority 0; policy accept; }
          add chain inet firewall input_always_allowed
          add rule inet firewall input_always_allowed icmp type { destination-unreachable, echo-request, parameter-problem, time-exceeded } accept
          add rule inet firewall input_always_allowed icmpv6 type { destination-unreachable, echo-request, nd-neighbor-advert, nd-neighbor-solicit, nd-router-solicit, packet-too-big, parameter-problem, time-exceeded } accept
          add chain inet firewall input_always_allowed_lan
          add rule inet firewall input_always_allowed_lan jump input_always_allowed
          add rule inet firewall input_always_allowed_lan meta l4proto udp th dport { "bootps", "ntp", "dhcpv6-server" } accept
          add rule inet firewall input_always_allowed_lan meta l4proto { tcp, udp } th dport "domain" accept

          add table ip nat
          add chain ip nat prerouting { type nat hook prerouting priority 100; policy accept; }
          add chain ip nat postrouting { type nat hook postrouting priority 100; policy accept; }

          # standard configuration
          # NAT masquerading
          add rule ip nat postrouting ip saddr { ${lanIPv4Networks} } oifname $DEV_WAN masquerade

          # not_in_internet
          add chain inet firewall not_in_internet
          add rule inet firewall not_in_internet iifname { $DEV_WAN } ip saddr { ${v4BogonNetworks} } drop
          add rule inet firewall not_in_internet iifname { $DEV_WAN6 } ip6 saddr { ${v6BogonNetworks} } drop
          add rule inet firewall not_in_internet oifname { $DEV_WAN } ip daddr { ${v4BogonNetworks} } drop
          add rule inet firewall not_in_internet oifname { $DEV_WAN6 } ip6 daddr { ${v6BogonNetworks} } drop
          add rule inet firewall input jump not_in_internet
          add rule inet firewall forward jump not_in_internet
          add rule inet firewall output jump not_in_internet

          # wireguard
          add chain inet firewall input_wireguard
          add rule inet firewall input_wireguard meta l4proto { udp } th dport { ${wireguardPorts} } accept
          add rule inet firewall input jump input_wireguard

          # allow_to_internet
          add chain inet firewall allow_to_internet
          add rule inet firewall allow_to_internet oifname { $DEV_WAN, $DEV_WAN6 } accept

          # input_wan
          add chain inet firewall input_wan
          add rule inet firewall input_wan icmp type echo-request limit rate 5/second accept
          add rule inet firewall input_wan icmpv6 type echo-request limit rate 5/second accept
          add rule inet firewall input iifname { $DEV_WAN, $DEV_WAN6 } jump input_wan

          # forward_from_wan
          add chain inet firewall forward_from_wan
          add rule inet firewall forward_from_wan icmpv6 type echo-request accept
          add rule inet firewall forward iifname { $DEV_WAN, $DEV_WAN6 } jump forward_from_wan

          # custom policy configuration
          # DEV_MGMT, DEV_TRUSTED, DEV_WG_TRUSTED policies
          add chain inet firewall input_trusted
          add rule inet firewall input_trusted jump input_always_allowed_lan
          add rule inet firewall input_trusted meta l4proto tcp th dport { 9153, ${toString config.services.prometheus.exporters.blackbox.port}, ${toString config.services.prometheus.exporters.kea.port}, ${toString config.services.prometheus.exporters.node.port}, ${toString config.services.prometheus.exporters.wireguard.port} } accept
          add rule inet firewall input_trusted meta l4proto tcp th dport "ssh" log prefix "input ssh - " accept
          add rule inet firewall input_trusted meta l4proto udp th dport "tftp" log prefix "input tftp - " accept
          add rule inet firewall input_trusted meta l4proto { tcp, udp } th dport { ${toString config.services.iperf3.port} } log prefix "input iperf3 - " accept
          add rule inet firewall input iifname { $DEV_MGMT, $DEV_TRUSTED, $DEV_WG_TRUSTED } jump input_trusted
          add chain inet firewall forward_from_trusted
          add rule inet firewall forward_from_trusted jump allow_to_internet
          add rule inet firewall forward_from_trusted accept
          add rule inet firewall forward iifname { $DEV_MGMT, $DEV_TRUSTED, $DEV_WG_TRUSTED } jump forward_from_trusted

          # DEV_WG_WWW policies
          add chain inet firewall input_wg_www
          add rule inet firewall input_wg_www jump input_always_allowed
          add rule inet firewall input_wg_www meta l4proto tcp th dport 19531 accept # systemd-journal-gatewayd
          add rule inet firewall input iifname $DEV_WG_WWW jump input_wg_www

          # DEV_IOT, DEV_WG_IOT, DEV_WORK policies
          add rule inet firewall input iifname { $DEV_IOT, $DEV_WG_IOT, $DEV_WORK } jump input_always_allowed_lan
          add chain inet firewall forward_from_iot
          add rule inet firewall forward_from_iot jump allow_to_internet
          add rule inet firewall forward_from_iot oifname { $DEV_IOT, $DEV_WG_IOT } accept
          add rule inet firewall forward iifname { $DEV_IOT, $DEV_WG_IOT } jump forward_from_iot
          add chain inet firewall forward_from_work
          add rule inet firewall forward_from_work jump allow_to_internet
          add rule inet firewall forward_from_work oifname { $DEV_WORK } accept
          add rule inet firewall forward iifname { $DEV_WORK } jump forward_from_iot
        '';
    };
  };
}
