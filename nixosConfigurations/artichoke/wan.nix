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
        linkConfig.RequiredFamilyForOnline = "ipv6";
        routes = map
          (destination: {
            routeConfig = { Destination = destination; Type = "unreachable"; };
          }) [
          "::/128" # Node-scope unicast unspecified address
          "::1/128" # Node-scope unicast loopback address
          "::ffff:0:0/96" # IPv4-mapped addresses
          "::/96" # IPv4-compatible addresses
          "100::/64" # Remotely triggered black hole addresses
          "2001:10::/28" # Overlay routable cryptographic hash identifiers (ORCHID)
          "2001:db8::/32" # Documentation prefix
          "fc00::/7" # Unique local addresses (ULA)
          "fe80::/10" # Link-local unicast
          "fec0::/10" # Site-local unicast (deprecated)
          "ff00::/8" # Multicast (Note: ff0e:/16 is global scope and may appear on the global internet.)
          "2002::/24" # 6to4 bogon (0.0.0.0/8)
          "2002:a00::/24" # 6to4 bogon (10.0.0.0/8)
          "2002:7f00::/24" # 6to4 bogon (127.0.0.0/8)
          "2002:a9fe::/32" # 6to4 bogon (169.254.0.0/16)
          "2002:ac10::/28" # 6to4 bogon (172.16.0.0/12)
          "2002:c000::/40" # 6to4 bogon (192.0.0.0/24)
          "2002:c000:200::/40" # 6to4 bogon (192.0.2.0/24)
          "2002:c0a8::/32" # 6to4 bogon (192.168.0.0/16)
          "2002:c612::/31" # 6to4 bogon (198.18.0.0/15)
          "2002:c633:6400::/40" # 6to4 bogon (198.51.100.0/24)
          "2002:cb00:7100::/40" # 6to4 bogon (203.0.113.0/24)
          "2002:e000::/20" # 6to4 bogon (224.0.0.0/4)
          "2002:f000::/20" # 6to4 bogon (240.0.0.0/4)
          "2002:ffff:ffff::/48" # 6to4 bogon (255.255.255.255/32)
          "2001::/40" # Teredo bogon (0.0.0.0/8)
          "2001:0:a00::/40" # Teredo bogon (10.0.0.0/8)
          "2001:0:7f00::/40" # Teredo bogon (127.0.0.0/8)
          "2001:0:a9fe::/48" # Teredo bogon (169.254.0.0/16)
          "2001:0:ac10::/44" # Teredo bogon (172.16.0.0/12)
          "2001:0:c000::/56" # Teredo bogon (192.0.0.0/24)
          "2001:0:c000:200::/56" # Teredo bogon (192.0.2.0/24)
          "2001:0:c0a8::/48" # Teredo bogon (192.168.0.0/16)
          "2001:0:c612::/47" # Teredo bogon (198.18.0.0/15)
          "2001:0:c633:6400::/56" # Teredo bogon (198.51.100.0/24)
          "2001:0:cb00:7100::/56" # Teredo bogon (203.0.113.0/24)
          "2001:0:e000::/36" # Teredo bogon (224.0.0.0/4)
          "2001:0:f000::/36" # Teredo bogon (240.0.0.0/4)
          "2001:0:ffff:ffff::/64" # Teredo bogon (255.255.255.255/32)
        ];
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
        linkConfig.RequiredFamilyForOnline = "ipv4";
        routes = map
          (destination: {
            routeConfig = { Destination = destination; Type = "unreachable"; };
          }) [
          "0.0.0.0/8" # "This" network
          "10.0.0.0/8" # Private-use networks
          "100.64.0.0/10" # Carrier-grade NAT
          "127.0.0.0/8" # Loopback
          "127.0.53.53" # Name collision occurrence
          "169.254.0.0/16" # Link local
          "172.16.0.0/12" # Private-use networks
          "192.0.0.0/24" # IETF protocol assignments
          "192.0.2.0/24" # TEST-NET-1
          "192.168.0.0/16" # Private-use networks
          "198.18.0.0/15" # Network interconnect device benchmark testing
          "198.51.100.0/24" # TEST-NET-2
          "203.0.113.0/24" # TEST-NET-3
          "224.0.0.0/4" # Multicast
          "240.0.0.0/4" # Reserved for future use
          "255.255.255.255/32" # Limited broadcast
        ];
      };
    };
  };
}
