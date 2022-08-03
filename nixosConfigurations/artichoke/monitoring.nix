{ pkgs, ... }:
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
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [ "ethtool" "network_route" "systemd" ];
    };
    wireguard.enable = true;
    blackbox = {
      enable = true;
      configFile = "${blackboxConfig}";
    };
  };
}
