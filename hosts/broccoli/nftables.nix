{ config, lib, ... }: {
  networking.nftables = {
    enable = true;
    ruleset = with config.networking.interfaces; ''
      define DEV_WAN = ${eno1.name}
      define DEV_WAN6 = ${hurricane.name}
      define DEV_PUBWAN = ${pubwan.name}
      define DEV_PUBLAN = ${publan.name}
      define DEV_TRUSTED = ${trusted.name}
      define DEV_IOT = ${iot.name}
      define DEV_GUEST = ${guest.name}
      define DEV_MGMT = ${mgmt.name}
      define NET_ALL = 192.168.0.0/16

      table inet filter {

          chain input_lan_icmp {
              # accepting ping (icmp-echo-request) for diagnostic purposes.
              # However, it also lets probes discover this host is alive.
              # This sample accepts them within a certain rate limit:
 
	      ip6 nexthdr icmpv6 icmpv6 type {
		  echo-request,
		  destination-unreachable,
		  packet-too-big,
		  time-exceeded,
		  parameter-problem,
		  nd-neighbor-solicit,
		  nd-neighbor-advert,
	      } accept
	      ip protocol icmp icmp type {
		  echo-request,
		  destination-unreachable,
		  time-exceeded,
		  parameter-problem,
	      }  accept
          }

          chain input_wan {
              icmp type echo-request limit rate 5/second accept
              icmpv6 type echo-request limit rate 5/second accept
          }

          chain input_always_allowed {
              jump input_lan_icmp

              meta l4proto { tcp, udp } th dport 53 accept
              udp dport 67 accept
          }

          chain input_private_trusted {
              jump input_always_allowed

              # allow SSH from the private trusted network
              tcp dport ssh log prefix "input ssh - " accept
          }

          chain input_private_untrusted {
              jump input_always_allowed
          }

          chain input {
              type filter hook input priority 0; policy drop;

              # Allow traffic from established and related packets, drop invalid
              ct state vmap { established : accept, related : accept, invalid : drop }

              # allow loopback traffic, anything else jump to chain for further evaluation
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

          chain allow_to_internet {
              oifname { $DEV_WAN, $DEV_WAN6 } accept
          }

          chain iot {
              jump allow_to_internet
              oifname $DEV_IOT accept
          }

          chain forward {
              type filter hook forward priority 0; policy drop;

              # Allow traffic from established and related packets, drop invalid
              ct state vmap { established : accept, related : accept, invalid : drop }

              oifname { $DEV_WAN } jump not_in_internet

              # connections from the internal net to the internet or to other
              # internal nets are allowed
              iifname vmap {
                  $DEV_PUBWAN : jump allow_to_internet,
                  $DEV_PUBLAN : jump allow_to_internet,
                  $DEV_TRUSTED : accept,
                  $DEV_IOT : jump iot,
                  $DEV_GUEST : jump allow_to_internet,
                  $DEV_MGMT : accept,
              }

              # the rest is dropped by the above policy
              log prefix "forward drop - "
          }

      }

      table ip nat {

          chain postrouting {
              type nat hook postrouting priority 100; policy accept;

              # masquerade private IP addresses
              ip saddr $NET_ALL oifname $DEV_WAN masquerade
          }

      }
    '';
  };
}
