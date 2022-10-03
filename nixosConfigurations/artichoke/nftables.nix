{ config, lib, inventory, ... }: {
  networking = {
    nat.enable = false;
    firewall.enable = false;
    nftables = {
      enable = true;
      ruleset = with config.systemd.network;
        let
          v4BogonNetworks = lib.concatMapStringsSep
            ", "
            (route: route.routeConfig.Destination)
            (networks.wan.routes);
          v6BogonNetworks = lib.concatMapStringsSep
            ", "
            (route: route.routeConfig.Destination)
            (networks.hurricane.routes);
        in
        ''
          define DEV_WAN = ${networks.wan.name}
          define DEV_WAN6 = ${networks.hurricane.name}
          define DEV_MGMT = ${networks.mgmt.name}
          define NET_MGMT = ${inventory.networks.mgmt.networkIPv4Cidr}
          define DEV_WG_PUBLIC = ${networks.wg-public.name}
          define NET_WG_PUBLIC = ${inventory.networks.wg-public.networkIPv4Cidr}
          define DEV_TRUSTED = ${networks.trusted.name}
          define NET_TRUSTED = ${inventory.networks.trusted.networkIPv4Cidr}
          define DEV_WG_TRUSTED = ${networks.wg-trusted.name}
          define NET_WG_TRUSTED = ${inventory.networks.wg-trusted.networkIPv4Cidr}
          define DEV_IOT = ${networks.iot.name}
          define NET_IOT = ${inventory.networks.iot.networkIPv4Cidr}
          define DEV_WG_IOT = ${networks.wg-iot.name}
          define NET_WG_IOT = ${inventory.networks.wg-iot.networkIPv4Cidr}
          define DEV_WORK = ${networks.work.name}
          define NET_WORK = ${inventory.networks.work.networkIPv4Cidr}

          table inet firewall {
              chain input_wan {
                  # accepting ping (icmp-echo-request) for diagnostic purposes.
                  # However, it also lets probes discover this host is alive. This
                  # sample accepts them within a certain rate limit:
                  icmp type echo-request limit rate 5/second accept
                  icmpv6 type echo-request limit rate 5/second accept
              }

              chain input_always_allowed {
                  icmp type {
                      destination-unreachable,
                      echo-request,
                      parameter-problem,
                      time-exceeded,
                  } accept
                  icmpv6 type {
                      destination-unreachable,
                      echo-request,
                      nd-neighbor-advert,
                      nd-neighbor-solicit,
                      nd-router-solicit,
                      packet-too-big,
                      parameter-problem,
                      time-exceeded,
                  } accept

                  meta l4proto udp th dport {
                      123,  # ntp
                      547,  # dhcpv6
                      67,   # dhcpv4
                  } accept
                  meta l4proto { tcp, udp } th dport 53 accept # DNS
              }

              chain input_trusted {
                  jump input_always_allowed

                  meta l4proto tcp th dport {
                      9153, # coredns
                      ${toString config.services.prometheus.exporters.blackbox.port},
                      ${toString config.services.prometheus.exporters.node.port},
                      ${toString config.services.prometheus.exporters.wireguard.port},
                  } accept
                  meta l4proto tcp th dport ssh log prefix "input ssh - " accept
                  meta l4proto udp th dport 69 log prefix "input tftp - " accept
                  meta l4proto { tcp, udp } th dport {
                      ${toString config.services.iperf3.port},
                  } log prefix "input iperf3 - " accept
              }

              chain input_public {
                  jump input_always_allowed
                  meta l4proto tcp th dport {
                      19531, # systemd-journal-gatewayd
                  } accept
              }

              chain input {
                  type filter hook input priority 0; policy drop;

                  # Allow traffic from established and related packets, drop
                  # invalid
                  ct state vmap {
                      established : accept,
                      related : accept,
                      invalid : drop,
                  }

                  jump not_in_internet

                  # always allow wireguard traffic
                  meta l4proto { udp } th dport {
                      ${toString netdevs.wg-iot.wireguardConfig.ListenPort},
                      ${toString netdevs.wg-trusted.wireguardConfig.ListenPort},
                  } accept

                  # allow loopback traffic, anything else jump to chain for further
                  # evaluation
                  iifname vmap {
                      lo : accept,
                      $DEV_WAN : jump input_wan,
                      $DEV_WAN6 : jump input_wan,
                      $DEV_MGMT : jump input_trusted,
                      $DEV_WG_PUBLIC : jump input_public,
                      $DEV_TRUSTED : jump input_trusted,
                      $DEV_WG_TRUSTED : jump input_trusted,
                      $DEV_IOT : jump input_always_allowed,
                      $DEV_WG_IOT : jump input_always_allowed,
                      $DEV_WORK : jump input_always_allowed,
                  }

                  # the rest is dropped by the above policy
              }

              chain not_in_internet {
                  # Drop addresses that do not exist in the internet (RFC6890)
                  iifname { $DEV_WAN } ip saddr { ${v4BogonNetworks} } drop
                  iifname { $DEV_WAN6 } ip6 saddr { ${v6BogonNetworks} } drop

                  oifname { $DEV_WAN } ip daddr { ${v4BogonNetworks} } drop
                  oifname { $DEV_WAN6 } ip6 daddr { ${v6BogonNetworks} } drop
              }

              chain forward_from_wan {
                  icmpv6 type { echo-request } accept
                  oifname $DEV_WG_PUBLIC log prefix "forward wg-public - " accept
              }

              chain allow_to_internet {
                  oifname { $DEV_WAN, $DEV_WAN6 } accept
              }

              chain dont_allow_to_internet {
                  oifname { $DEV_WAN, $DEV_WAN6 } log prefix "not allowed to internet - " drop
              }

              chain forward_from_mgmt {
                  # TODO(jared): don't allow to internet
                  accept
              }

              chain forward_from_trusted {
                  jump allow_to_internet
                  oifname {
                      $DEV_MGMT,
                      $DEV_TRUSTED,
                      $DEV_WG_TRUSTED,
                      $DEV_IOT,
                      $DEV_WG_IOT,
                      $DEV_WORK,
                  } accept
              }

              chain forward_from_iot {
                  jump allow_to_internet
                  oifname {
                      $DEV_IOT,
                      $DEV_WG_IOT,
                  } accept
              }

              chain forward_from_work {
                  jump allow_to_internet
                  oifname {
                      $DEV_WORK,
                  } accept
              }

              chain forward {
                  type filter hook forward priority 0; policy drop;

                  # Allow traffic from established and related packets, drop
                  # invalid
                  ct state vmap {
                      established : accept,
                      related : accept,
                      invalid : drop,
                  }

                  jump not_in_internet

                  # connections from the internal net to the internet or to other
                  # internal nets are allowed
                  iifname vmap {
                      $DEV_WAN : jump forward_from_wan,
                      $DEV_WAN6 : jump forward_from_wan,
                      $DEV_MGMT : jump forward_from_mgmt,
                      $DEV_WG_PUBLIC : jump allow_to_internet,
                      $DEV_TRUSTED : jump forward_from_trusted,
                      $DEV_WG_TRUSTED : jump forward_from_trusted,
                      $DEV_IOT : jump forward_from_iot,
                      $DEV_WG_IOT : jump forward_from_iot,
                      $DEV_WORK : jump forward_from_work,
                  }

                  # the rest is dropped by the above policy
              }

              chain output {
                  type filter hook output priority 0; policy accept;

                  jump not_in_internet
              }
          }

          table ip nat {
              chain prerouting {
                  type nat hook prerouting priority 100; policy accept;
              }

              chain postrouting {
                  type nat hook postrouting priority 100; policy accept;

                  # masquerade private IP addresses
                  ip saddr {
                      $NET_MGMT,
                      $NET_WG_PUBLIC,
                      $NET_TRUSTED,
                      $NET_WG_TRUSTED,
                      $NET_IOT,
                      $NET_WG_IOT,
                      $NET_WORK,
                  } oifname $DEV_WAN masquerade
              }
          }
        '';
    };
  };
}
