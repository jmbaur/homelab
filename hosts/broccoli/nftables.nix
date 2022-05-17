{ config, lib, ... }: {
  networking.nftables = {
    enable = true;
    ruleset = with config.systemd.network; ''
      define DEV_WAN = ${networks.wan.matchConfig.Name}
      define DEV_WAN6 = ${networks.hurricane.matchConfig.Name}
      define DEV_PUBWAN = ${networks.pubwan.matchConfig.Name}
      define DEV_PUBLAN = ${networks.publan.matchConfig.Name}
      define DEV_TRUSTED = ${networks.trusted.matchConfig.Name}
      define DEV_IOT = ${networks.iot.matchConfig.Name}
      define DEV_GUEST = ${networks.guest.matchConfig.Name}
      define DEV_MGMT = ${networks.mgmt.matchConfig.Name}
      define DEV_WG_TRUSTED = ${networks.wg-trusted.matchConfig.Name}
      define DEV_WG_IOT = ${networks.wg-iot.matchConfig.Name}
      define NET_ALL = 192.168.0.0/16

      table inet firewall {
          chain input_wan {
              icmp type echo-request limit rate 5/second accept
              icmpv6 type echo-request limit rate 5/second accept
              meta l4proto { udp } th dport {
                  ${toString netdevs.wg-trusted.wireguardConfig.ListenPort},
                  ${toString netdevs.wg-iot.wireguardConfig.ListenPort},
              } log prefix "input wireguard - " accept
          }

          chain input_always_allowed {
              # accepting ping (icmp-echo-request) for diagnostic purposes.
              # However, it also lets probes discover this host is alive. This
              # sample accepts them within a certain rate limit:

              ip protocol icmp icmp type {
                  destination-unreachable,
                  echo-reply,
                  echo-request,
                  source-quench,
                  time-exceeded,
              } accept
              ip6 nexthdr icmpv6 icmpv6 type {
                  destination-unreachable,
                  echo-reply,
                  echo-request,
                  nd-neighbor-solicit,
                  nd-router-advert,
                  nd-neighbor-advert,
                  packet-too-big,
                  parameter-problem,
                  time-exceeded,
              } accept

              ip version 4 udp dport 67 accept # DHCP
              meta l4proto udp th dport 5353 accept # mDNS
              meta l4proto { tcp, udp } th dport 53 accept # DNS
          }

          chain input_private_trusted {
              jump input_always_allowed

              meta l4proto tcp th dport {
                  9153, # coredns
                  ${toString config.services.prometheus.exporters.node.port},
                  ${toString config.services.prometheus.exporters.smartctl.port},
                  ${toString config.services.prometheus.exporters.systemd.port},
                  ${toString config.services.prometheus.exporters.wireguard.port},
              } log prefix "input prometheus - " accept
              meta l4proto tcp th dport ssh log prefix "input ssh - " accept
              meta l4proto udp th dport 69 log prefix "input tftp - " accept
              meta l4proto { tcp, udp } th dport {
                  ${toString config.services.iperf3.port},
              } log prefix "input iperf3 - " accept
          }

          chain input_private_untrusted {
              jump input_always_allowed
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

              # allow loopback traffic, anything else jump to chain for further
              # evaluation
              iifname vmap {
                  lo : accept,
                  $DEV_WAN : jump input_wan,
                  $DEV_WAN6 : jump input_wan,
                  $DEV_PUBWAN : jump input_private_untrusted,
                  $DEV_PUBLAN : jump input_private_untrusted,
                  $DEV_TRUSTED : jump input_private_trusted,
                  $DEV_IOT : jump input_private_untrusted,
                  $DEV_GUEST : jump input_private_untrusted,
                  $DEV_MGMT : jump input_private_trusted,
                  $DEV_WG_TRUSTED : jump input_private_trusted,
                  $DEV_WG_IOT : jump input_private_untrusted,
              }

              # the rest is dropped by the above policy
              log prefix "input drop - "
          }

          chain not_in_internet {
              # Drop addresses that do not exist in the internet (RFC6890)
              ip daddr {
                  0.0.0.0/8,
                  10.0.0.0/8,
                  100.64.0.0/10,
                  127.0.0.0/8,
                  169.254.0.0/16,
                  172.16.0.0/12,
                  192.0.0.0/24,
                  192.0.2.0/24,
                  192.168.0.0/16,
                  192.88.99.0/24,
                  198.18.0.0/15,
                  198.51.100.0/24,
                  203.0.113.0/24,
                  224.0.0.0/4,
                  240.0.0.0/4,
              } log prefix "not in internet - " drop
          }

          chain forward_from_wan {
              icmpv6 type { echo-request } accept
              oifname $DEV_PUBWAN log prefix "forward pubwan - " accept
          }

          chain allow_to_internet {
              oifname { $DEV_WAN, $DEV_WAN6 } accept
          }

          chain iot {
              jump allow_to_internet
              oifname { $DEV_IOT, $DEV_PUBLAN, $DEV_WG_IOT } accept
              log prefix "did not match oifname *wireguard*"
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

              oifname { $DEV_WAN } jump not_in_internet

              # connections from the internal net to the internet or to other
              # internal nets are allowed
              iifname vmap {
                  $DEV_WAN : jump forward_from_wan,
                  $DEV_WAN6 : jump forward_from_wan,
                  $DEV_PUBWAN : jump allow_to_internet,
                  $DEV_PUBLAN : jump allow_to_internet,
                  $DEV_TRUSTED : accept,
                  $DEV_IOT : jump iot,
                  $DEV_GUEST : jump allow_to_internet,
                  $DEV_MGMT : accept,
                  $DEV_WG_TRUSTED : accept,
                  $DEV_WG_IOT : jump iot,
              }

              # the rest is dropped by the above policy
              log prefix "forward drop - "
          }
      }

      table ip nat {
          chain prerouting {
              type nat hook prerouting priority 100; policy accept;

              # # TODO(jared): don't hardcode the dnat address
              # iifname $DEV_WAN udp dport {
              #     ${toString netdevs.wg-trusted.wireguardConfig.ListenPort},
              # } dnat to 192.168.130.1
              #
              # # TODO(jared): don't hardcode the dnat address
              # iifname $DEV_WAN udp dport {
              #     ${toString netdevs.wg-iot.wireguardConfig.ListenPort},
              # } dnat to 192.168.140.1
          }

          chain postrouting {
              type nat hook postrouting priority 100; policy accept;

              # masquerade private IP addresses
              ip saddr $NET_ALL oifname $DEV_WAN masquerade
          }
      }
    '';
  };
}
