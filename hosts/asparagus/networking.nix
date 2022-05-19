{ config, lib, ... }: {
  networking = {
    hostName = "asparagus";
    useDHCP = lib.mkForce false;
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;
    networks = {
      wired_normal = {
        matchConfig.Name = "enp4s0";
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
      wired_mgmt = {
        matchConfig.Name = "enp6s0";
        networkConfig = {
          DHCP = "yes";
          IPv6PrivacyExtensions = true;
        };
        dhcpV4Config = {
          RouteMetric = 20;
          UseDomains = "yes";
          ClientIdentifier = "mac";
        };
        ipv6AcceptRAConfig.RouteMetric = 20;
      };
    };
  };
}
