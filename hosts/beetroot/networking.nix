{ config, lib, ... }: {
  systemd.services.systemd-networkd-wait-online.enable = false;
  systemd.network = {
    config = {
      networkConfig = {
        DHCP = "yes";
        IPv6PrivacyExtensions = true;
      };
      dhcpV4Config.UseDomains = true;
    };
    networks = {
      wired = {
        matchConfig.Name = "en*";
        dhcpV4Config.RouteMetric = 10;
        ipv6AcceptRAConfig.RouteMetric = 10;
      };
      wireless = {
        matchConfig.Name = "wl*";
        dhcpV4Config.RouteMetric = 20;
        ipv6AcceptRAConfig.RouteMetric = 20;
      };
    };
  };

  networking = {
    useDHCP = lib.mkForce false;
    hostName = "beetroot";
    useNetworkd = true;
    wireless.iwd.enable = true;
  };
}
