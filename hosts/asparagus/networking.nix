{ config, lib, ... }: {
  networking = {
    hostName = "asparagus";
    useDHCP = lib.mkForce false;
    useNetworkd = true;
  };

  systemd.network = {
    config = {
      networkConfig = {
        DHCP = "yes";
        IPv6PrivacyExtensions = true;
      };
      dhcpV4Config = {
        ClientIdentifier = "mac";
        UseDomains = "yes";
      };
    };
    networks = {
      wired_normal = {
        matchConfig.Name = "enp4s0";
        dhcpV4Config.RouteMetric = 10;
        ipv6AcceptRAConfig.RouteMetric = 10;
      };
      wired_mgmt = {
        matchConfig.Name = "enp6s0";
        dhcpV4Config.RouteMetric = 20;
        ipv6AcceptRAConfig.RouteMetric = 20;
      };
    };
  };
}
