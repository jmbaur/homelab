{ config, lib, ... }: {
  networking.nftables = {
    enable = true;
    ruleset = with config.networking.interfaces; ''
      define DEV_WAN = ${eno1.name}
      define DEV_WAN6 = ${hurricane.name}
      define DEV_PRIVATE = ${eno2.name}
      define DEV_PUBWAN = ${pubwan.name}
      define DEV_PUBLAN = ${publan.name}
      define DEV_TRUSTED = ${trusted.name}
      define DEV_IOT = ${iot.name}
      define DEV_GUEST = ${guest.name}
      define DEV_MGMT = ${mgmt.name}
      define NET_PUBWAN = 192.168.10.0/24
      define NET_PUBLAN = 192.168.20.0/24
      define NET_TRUSTED = 192.168.30.0/24
      define NET_IOT = 192.168.40.0/24
      define NET_GUEST = 192.168.50.0/24
      define NET_MGMT = 192.168.88.0/24
      define NET_ALL = 192.168.0.0/16

      table ip global {

          chain input_wan {
              # accepting ping (icmp-echo-request) for diagnostic purposes.
              # However, it also lets probes discover this host is alive.
              # This sample accepts them within a certain rate limit:
              #
              icmp type echo-request limit rate 5/second accept

              # allow SSH connections from some well-known internet host
              # ip saddr 81.209.165.42 tcp dport ssh accept
          }

          chain input_private_trusted {
              # accepting ping (icmp-echo-request) for diagnostic purposes.
              icmp type echo-request limit rate 5/second accept

              # allow DHCP, DNS and SSH from the private trusted network
              ip protocol . th dport vmap { tcp . 22 : accept, udp . 53 : accept, tcp . 53 : accept, udp . 67 : accept}
          }

          chain input_private_untrusted {
              # accepting ping (icmp-echo-request) for diagnostic purposes.
              icmp type echo-request limit rate 5/second accept

              # allow DHCP and DNS from the private untrusted network
              ip protocol . th dport vmap { udp . 53 : accept, tcp . 53 : accept, udp . 67 : accept}
          }

          chain input {
              type filter hook input priority 0; policy drop;

              # Allow traffic from established and related packets, drop invalid
              ct state vmap { established : accept, related : accept, invalid : drop }

              # allow loopback traffic, anything else jump to chain for further evaluation
              iifname vmap {
                  lo : accept,
                  $DEV_WAN : jump input_wan,
                  $DEV_PRIVATE : jump input_private_trusted,
                  $DEV_PUBWAN : jump input_private_untrusted,
                  $DEV_PUBLAN : jump input_private_untrusted,
                  $DEV_TRUSTED : jump input_private_trusted,
                  $DEV_IOT : jump input_private_untrusted,
                  $DEV_GUEST : jump input_private_untrusted,
                  $DEV_MGMT : jump input_private_trusted
              }

              # the rest is dropped by the above policy
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
                  240.0.0.0/4
              } drop
          }

          chain allow_to_internet {
              oifname $DEV_WAN accept
          }

          chain forward {
              type filter hook forward priority 0; policy drop;

              # Allow traffic from established and related packets, drop invalid
              ct state vmap { established : accept, related : accept, invalid : drop }

              oifname $DEV_WAN jump not_in_internet

              # connections from the internal net to the internet or to other
              # internal nets are allowed
              iifname vmap {
                  $DEV_PRIVATE : accept,
                  $DEV_PUBWAN : jump allow_to_internet,
                  $DEV_PUBLAN : jump allow_to_internet,
                  $DEV_TRUSTED : accept,
                  $DEV_IOT : jump allow_to_internet,
                  $DEV_GUEST : jump allow_to_internet,
                  $DEV_MGMT : accept
              }

              # the rest is dropped by the above policy
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
