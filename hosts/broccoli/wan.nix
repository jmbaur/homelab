{ config, secrets, ... }: {
  systemd.network = {
    netdevs = {
      hurricane = {
        tunnelConfig.Remote = secrets.networking.hurricane.remote;
        netdevConfig = {
          Name = "hurricane";
          Kind = "sit";
          MTUBytes = "1480";
        };
        tunnelConfig = {
          Local = "any";
          TTL = 255;
        };
      };
    };

    networks = {
      hurricane = {
        name =
          config.systemd.network.netdevs.hurricane.netdevConfig.Name;
        networkConfig = {
          Address = "${secrets.networking.hurricane.address}/${toString secrets.networking.hurricane.cidr}";
          Gateway = secrets.networking.hurricane.gateway;
        };
      };

      wan = {
        name = "enp0s20f0";
        networkConfig = {
          Tunnel = config.systemd.network.netdevs.hurricane.netdevConfig.Name;
          DHCP = "ipv4";
          IPv6AcceptRA = false; # TODO(jared): get a better ISP
          LinkLocalAddressing = "no";
          IPForward = true;
        };
        dhcpV4Config = {
          UseDNS = false;
          UseDomains = false;
        };
      };
    };
  };
}
