{ config, pkgs, ... }:
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
      enable = true;
      configFile = "${blackboxConfig}";
    };
    node = {
      enable = true;
      enabledCollectors = [ "ethtool" "network_route" "systemd" ];
    };
    wireguard.enable = true;
    kea = {
      enable = true;
      controlSocketPaths = [
        config.services.kea.dhcp6.settings.control-socket.socket-name
      ];
    };
  };
  nixpkgs.overlays = [
    (_: prev: {
      prometheus-kea-exporter = prev.prometheus-kea-exporter.overrideAttrs (old: {
        patches = [
          (prev.fetchpatch {
            url = "https://patch-diff.githubusercontent.com/raw/mweinelt/kea-exporter/pull/26.patch";
            sha256 = "1knlixmralsh46mxp56kp4rd719mbsdv3vphms0il6cmpriba0wd";
          })
        ];
      });
    })
  ];
}
