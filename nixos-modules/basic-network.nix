{ lib, config, ... }:
let
  cfg = config.custom.basicNetwork;
in
{
  options.custom.basicNetwork = {
    enable = lib.mkEnableOption "basic network setup";
  };

  config = lib.mkIf cfg.enable {
    services.resolved.enable = true;

    networking.useDHCP = false;

    systemd.network = {
      enable = true;
      networks = {
        wireless = lib.mkIf (with config.networking.wireless; enable || iwd.enable) {
          DHCP = "yes";
          matchConfig.Type = "wlan";
          dhcpV4Config = {
            UseDomains = "route";
            RouteMetric = 2048;
          };
          ipv6AcceptRAConfig = {
            UseDomains = "route";
            RouteMetric = 2048;
          };
          networkConfig = {
            IPv6PrivacyExtensions = "kernel";
            Domains = "~.";
            MulticastDNS = true;
          };
        };
        wired = {
          DHCP = "yes";
          matchConfig.Type = "ether";
          dhcpV4Config = {
            UseDomains = "route";
            RouteMetric = 1024;
          };
          ipv6AcceptRAConfig = {
            UseDomains = "route";
            RouteMetric = 1024;
          };
          networkConfig = {
            IPv6PrivacyExtensions = "kernel";
            Domains = "~.";
            MulticastDNS = true;
          };
        };
      };
    };
  };
}
