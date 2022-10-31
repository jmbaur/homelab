{ config, lib, pkgs, inventory, ... }:
let
  blackboxConfig = (pkgs.formats.yaml { }).generate "blackbox-config" {
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
  };
in
{
  services.journald.enableHttpGateway = true;
  services.prometheus.exporters = {
    blackbox = {
      enable = false;
      configFile = "${blackboxConfig}";
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
            AllowedIPs = ${peer.ipv4},${peer.ipv6.ula}
          '')
          (lib.flatten
            (map
              (name: lib.attrValues inventory.networks.${name}.hosts)
              [ "wg-iot" "wg-trusted" ]
            )
          )
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

  nixpkgs.overlays = [
    (_: prev: {
      prometheus-kea-exporter = prev.prometheus-kea-exporter.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (prev.fetchpatch {
            url = "https://patch-diff.githubusercontent.com/raw/mweinelt/kea-exporter/pull/30.patch";
            sha256 = "0876kc191lw1cq5v4bd6wh139iw51k70cqkwdmjyz40pd61xp16q";
          })
        ];
      });
    })
  ];
}
