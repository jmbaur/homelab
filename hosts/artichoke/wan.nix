{ config, secrets, ... }: {
  networking.useDHCP = false;

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
        linkConfig = {
          RequiredForOnline = "routable";
          # RequiredFamilyForOnline = "ipv6"; # TODO(jared): https://github.com/NixOS/nixpkgs/pull/182876
        };
      };

      wan = {
        name = config.systemd.network.links."10-wan".linkConfig.Name;
        DHCP = "ipv4";
        networkConfig = {
          Tunnel = config.systemd.network.netdevs.hurricane.netdevConfig.Name;
          IPv6AcceptRA = false; # TODO(jared): get a better ISP
          LinkLocalAddressing = "no";
          IPForward = true;
        };
        dhcpV4Config = {
          UseDNS = false;
          UseDomains = false;
        };
        linkConfig = {
          RequiredForOnline = "routable";
          # RequiredFamilyForOnline = "ipv4"; # TODO(jared): https://github.com/NixOS/nixpkgs/pull/182876
        };
      };
    };
  };
}
