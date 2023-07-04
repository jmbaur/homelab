{ lib, config, ... }:
let
  cfg = config.custom.basicNetwork;
in
{
  options.custom.basicNetwork = {
    enable = lib.mkEnableOption "basic network setup";
    hasWireless = lib.mkEnableOption "wireless";
  };

  config = lib.mkIf cfg.enable {
    services.resolved.enable = true;

    networking = {
      useDHCP = false;
      wireless.enable = lib.mkForce false;
      wireless.iwd.enable = lib.mkDefault cfg.hasWireless;
    };

    systemd.network = {
      enable = true;
      networks = {
        wireless = {
          enable = cfg.hasWireless;
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
          };
        };
      };
    };
  };
}
