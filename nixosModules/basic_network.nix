{ lib, config, ... }:
with lib;
let
  cfg = config.custom.basicNetwork;
in
{
  options.custom.basicNetwork = {
    enable = mkEnableOption "basic network setup";
    hasWireless = mkEnableOption "wireless";
    wiredMatch = mkOption {
      type = types.str;
      default = "en*";
      description = ''
        The networkd-compatible regex (see systemd.networkd(5)) to use
        for matching a wired network interface.
      '';
    };
    wirelessMatch = mkOption {
      type = types.str;
      default = "wl*";
      description = ''
        The networkd-compatible regex (see systemd.networkd(5)) to use
        for matching a wireless network interface.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.resolved.enable = true;

    networking = {
      useDHCP = false;
      useNetworkd = true;
      wireless.iwd.enable = true;
    };

    systemd.network = {
      networks = {
        wireless = {
          name = cfg.wirelessMatch;
          DHCP = "yes";
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
          name = cfg.wiredMatch;
          DHCP = "yes";
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
