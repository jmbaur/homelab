{ config, lib, ... }: {
  networking.nftables = {
    enable = true;
    ruleset = with config.systemd.network; ''
      define DEV_WAN = ${networks.wan.name}
      define DEV_WAN6 = ${networks.hurricane.name}
      define DEV_PUBWAN = ${networks.pubwan.name}
      define DEV_PUBLAN = ${networks.publan.name}
      define DEV_TRUSTED = ${networks.trusted.name}
      define DEV_IOT = ${networks.iot.name}
      define DEV_WORK = ${networks.work.name}
      define DEV_MGMT = ${networks.mgmt.name}
      define DEV_WG_TRUSTED = ${networks.wg-trusted.name}
      define DEV_WG_IOT = ${networks.wg-iot.name}
      define NET_ALL = 192.168.0.0/16

      table inet firewall {
          chain input_wan {
              # accepting ping (icmp-echo-request) for diagnostic purposes.
              # However, it also lets probes discover this host is alive. This
              # sample accepts them within a certain rate limit:
              icmp type echo-request limit rate 5/second accept
              icmpv6 type echo-request limit rate 5/second accept

              meta l4proto { udp } th dport {
                  ${toString netdevs.wg-trusted.wireguardConfig.ListenPort},
                  ${toString netdevs.wg-iot.wireguardConfig.ListenPort},
              } log prefix "input wireguard - " accept
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
                  67, # dhcpv4
                  547, # dhcpv6
              } accept
              meta l4proto { tcp, udp } th dport 53 accept # DNS
          }

          chain input_private_trusted {
              jump input_always_allowed

              meta l4proto tcp th dport {
                  9153, # coredns
                  ${toString config.services.prometheus.exporters.kea.port},
                  ${toString config.services.prometheus.exporters.node.port},
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
                  $DEV_WORK : jump input_private_untrusted,
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

          chain forward_trusted {
              jump allow_to_internet
              oifname {
                  $DEV_IOT,
                  $DEV_WG_IOT,
                  $DEV_TRUSTED,
                  $DEV_WG_TRUSTED,
                  $DEV_PUBLAN,
                  $DEV_MGMT,
              } accept
          }

          chain forward_iot {
              jump allow_to_internet
              oifname {
                  $DEV_IOT,
                  $DEV_WG_IOT,
                  $DEV_PUBLAN,
              } accept
          }

          chain forward_work {
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

              oifname { $DEV_WAN } jump not_in_internet

              # connections from the internal net to the internet or to other
              # internal nets are allowed
              iifname vmap {
                  $DEV_WAN : jump forward_from_wan,
                  $DEV_WAN6 : jump forward_from_wan,
                  $DEV_PUBWAN : jump allow_to_internet,
                  $DEV_PUBLAN : jump allow_to_internet,
                  $DEV_TRUSTED : jump forward_trusted,
                  $DEV_IOT : jump forward_iot,
                  $DEV_WORK : jump forward_work,
                  $DEV_MGMT : accept,
                  $DEV_WG_TRUSTED : jump forward_trusted,
                  $DEV_WG_IOT : jump forward_iot,
              }

              # the rest is dropped by the above policy
              log prefix "forward drop - "
          }
      }

      table ip nat {
          chain prerouting {
              type nat hook prerouting priority 100; policy accept;
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
