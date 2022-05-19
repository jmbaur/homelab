{ config, lib, ... }: {
  systemd.services.systemd-networkd-wait-online.enable = false;
  systemd.network = {
    networks = {
      wired = {
        matchConfig.Name = "en*";
        networkConfig = {
          DHCP = "yes";
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config = {
          RouteMetric = 10;
          UseDomains = "yes";
        };
        ipv6AcceptRAConfig.RouteMetric = 10;
      };

      wireless = {
        matchConfig.Name = "wl*";
        networkConfig = {
          DHCP = "yes";
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config = {
          RouteMetric = 20;
          UseDomains = "yes";
        };
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
