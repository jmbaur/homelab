{ pkgs, inventory, ... }:
let
  blackboxConfig = (pkgs.formats.yaml { }).generate "blackbox-config" {
    modules = {
      ipv6_connectivity = {
        prober = "icmp";
        timeout = "5s";
        icmp = {
          preferred_ip_protocol = "ip6";
          source_ip_address = "2606:4700:4700::1111";
          ip_protocol_fallback = false;
        };
      };
      ipv4_connectivity = {
        prober = "icmp";
        timeout = "5s";
        icmp = {
          preferred_ip_protocol = "ip4";
          source_ip_address = "1.1.1.1";
          ip_protocol_fallback = false;
        };
      };
      vpn_subdomain_A = {
        prober = "dns";
        dns = {
          query_type = "A";
          query_name = "vpn.${inventory.tld}";
          valid_rcodes = [ "NOERROR" ];
        };
      };
      vpn_subdomain_AAAA = {
        prober = "dns";
        dns = {
          query_type = "AAAA";
          query_name = "vpn.${inventory.tld}";
          valid_rcodes = [ "NOERROR" ];
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
