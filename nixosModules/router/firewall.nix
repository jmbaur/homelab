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
              }

              chain input_always_allowed_lan {
                  jump input_always_allowed
                  meta l4proto udp th dport { "ntp", "dhcpv6-server", "bootps" } accept
                  meta l4proto { tcp, udp } th dport "domain" accept
              }

              chain input_trusted {
                  jump input_always_allowed_lan

                  meta l4proto tcp th dport {
                      9153, # coredns
                      ${toString config.services.prometheus.exporters.blackbox.port},
                      ${toString config.services.prometheus.exporters.kea.port},
                      ${toString config.services.prometheus.exporters.node.port},
                      ${toString config.services.prometheus.exporters.wireguard.port},
                  } accept
                  meta l4proto tcp th dport "ssh" log prefix "input ssh - " accept
                  meta l4proto udp th dport "tftp" log prefix "input tftp - " accept
                  meta l4proto { tcp, udp } th dport {
                      ${toString config.services.iperf3.port},
                  } log prefix "input iperf3 - " accept
              }

              chain input_wg_www {
                  jump input_always_allowed
                  meta l4proto tcp th dport {
                      19531, # systemd-journal-gatewayd
                  } accept
              }

              chain not_in_internet {
                  # Drop addresses that do not exist in the internet (RFC6890)
                  iifname { $DEV_WAN } ip saddr { ${v4BogonNetworks} } drop
                  iifname { $DEV_WAN6 } ip6 saddr { ${v6BogonNetworks} } drop

                  oifname { $DEV_WAN } ip daddr { ${v4BogonNetworks} } drop
                  oifname { $DEV_WAN6 } ip6 daddr { ${v6BogonNetworks} } drop
              }

              chain input_wireguard {
                  meta l4proto { udp } th dport { ${wireguardPorts} } accept
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
                  jump input_wireguard

                  # allow loopback traffic, anything else jump to chain for further
                  # evaluation
                  iifname vmap {
                      lo : accept,
                      $DEV_WAN : jump input_wan,
                      $DEV_WAN6 : jump input_wan,
                      $DEV_MGMT : jump input_trusted,
                      $DEV_WG_WWW : jump input_wg_www,
                      $DEV_TRUSTED : jump input_trusted,
                      $DEV_WG_TRUSTED : jump input_trusted,
                      $DEV_IOT : jump input_always_allowed_lan,
                      $DEV_WG_IOT : jump input_always_allowed_lan,
                      $DEV_WORK : jump input_always_allowed_lan,
                  }

                  # the rest is dropped by the above policy
              }

              chain forward_from_wan {
                  icmpv6 type { echo-request } accept
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
                  oifname { $DEV_WORK } accept
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
                  ip saddr { ${lanIPv4Networks} } oifname $DEV_WAN masquerade
              }
          }
        '';
    };
  };
}
