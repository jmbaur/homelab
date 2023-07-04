{ lib, config, ... }:
let
  cfg = config.custom.basicNetwork;
in
{
  options.custom.basicNetwork = {
    enable = lib.mkEnableOption "basic network setup";
    hasWireless = lib.mkEnableOption "wireless";
    wiredMatch = lib.mkOption {
      type = lib.types.str;
      default = "en*";
      description = ''
        The networkd-compatible regex (see systemd.networkd(5)) to use
        for matching a wired network interface.
      '';
    };
    wirelessMatch = lib.mkOption {
      type = lib.types.str;
      default = "wl*";
      description = ''
        The networkd-compatible regex (see systemd.networkd(5)) to use
        for matching a wireless network interface.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.resolved.enable = true;

    networking = {
      useDHCP = false;
      wireless.enable = lib.mkForce false;
      wireless.iwd.enable = lib.mkDefault true;
    };

    systemd.network = {
      enable = true;
      networks = {
        wireless = {
          enable = cfg.hasWireless;
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
