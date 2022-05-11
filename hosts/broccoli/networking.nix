{ config, lib, pkgs, ... }: {
  networking = {
    hostName = "broccoli";
    useDHCP = false;
    useNetworkd = true;
    nameservers = [ "127.0.0.1" "::1" ];
    search = [ "home.arpa" ];
    stevenBlackHosts.enable = true;
    nat.enable = false;
    firewall.enable = false;
  };

  systemd.network = {
    enable = true;
    netdevs =
      let
        mkVlanNetdev = name: id: {
          matchConfig.Virtualization = "no";
          netdevConfig = { Name = name; Kind = "vlan"; };
          vlanConfig.Id = id;
        };
      in
      {
        pubwan = mkVlanNetdev "pubwan" 10;
        publan = mkVlanNetdev "publan" 20;
        trusted = mkVlanNetdev "trusted" 30;
        iot = mkVlanNetdev "iot" 40;
        guest = mkVlanNetdev "guest" 50;
        mgmt = mkVlanNetdev "mgmt" 88;

        wg-trusted = {
          netdevConfig = {
            Name = "wg-trusted";
            Kind = "wireguard";
          };
          wireguardConfig = {
            ListenPort = 51830;
            PrivateKeyFile = "/run/secrets/wg-trusted";
          };
          wireguardPeers = [ ];
        };

        wg-iot = {
          netdevConfig = {
            Name = "wg-iot";
            Kind = "wireguard";
          };
          wireguardConfig = {
            ListenPort = 51840;
            PrivateKeyFile = "/run/secrets/wg-iot";
          };
          wireguardPeers = [ ];
        };

        hurricane = {
          netdevConfig = {
            Name = "hurricane";
            Kind = "sit";
            MTUBytes = "1480";
          };
          tunnelConfig = {
            Local = "dhcp4";
            TTL = 255;
          };
        };
      };

    networks = {
      wan = {
        matchConfig.Name = "enp0s20f0";
        networkConfig = {
          Tunnel = config.systemd.network.netdevs.hurricane.netdevConfig.Name;
          DHCP = "ipv4";
          IPv6AcceptRA = false; # TODO(jared): get a better ISP
        };
      };

      vlanMaster = {
        matchConfig.Name = "enp4s0";
        networkConfig.VLAN = builtins.map
          (name: config.systemd.network.netdevs.${name}.netdevConfig.Name)
          [ "pubwan" "publan" "trusted" "iot" "guest" "mgmt" ];
      };

      pubwan = {
        matchConfig.Name =
          config.systemd.network.netdevs.pubwan.netdevConfig.Name;
        networkConfig.Address = [
          "192.168.10.1/24"
          "${config.router.ulaPrefix}:a::1/64"
          "${config.router.guaPrefix}:a::1/64"
        ];
      };

      publan = {
        matchConfig.Name =
          config.systemd.network.netdevs.publan.netdevConfig.Name;
        networkConfig.Address = [
          "192.168.20.1/24"
          "${config.router.ulaPrefix}:14::1/64"
          "${config.router.guaPrefix}:14::1/64"
        ];
      };

      trusted = {
        matchConfig.Name =
          config.systemd.network.netdevs.trusted.netdevConfig.Name;
        networkConfig.Address = [
          "192.168.30.1/24"
          "${config.router.ulaPrefix}:1e::1/64"
          "${config.router.guaPrefix}:1e::1/64"
        ];
      };

      iot = {
        matchConfig.Name =
          config.systemd.network.netdevs.iot.netdevConfig.Name;
        networkConfig.Address = [
          "192.168.40.1/24"
          "${config.router.ulaPrefix}:28::1/64"
          "${config.router.guaPrefix}:28::1/64"
        ];
      };

      guest = {
        matchConfig.Name =
          config.systemd.network.netdevs.guest.netdevConfig.Name;
        networkConfig.Address = [
          "192.168.50.1/24"
          "${config.router.ulaPrefix}:32::1/64"
          "${config.router.guaPrefix}:32::1/64"
        ];
      };

      mgmt = {
        matchConfig.Name =
          config.systemd.network.netdevs.mgmt.netdevConfig.Name;
        networkConfig.Address = [
          "192.168.88.1/24"
          "${config.router.ulaPrefix}:58::1/64"
          "${config.router.guaPrefix}:58::1/64"
        ];
      };

      wg-trusted = {
        matchConfig.Name =
          config.systemd.network.netdevs.wg-trusted.netdevConfig.Name;
        networkConfig.Address = [
          "192.168.130.1/24"
          "${config.router.ulaPrefix}:82::1/64"
          "${config.router.guaPrefix}:82::1/64"
        ];
      };

      wg-iot = {
        matchConfig.Name =
          config.systemd.network.netdevs.wg-iot.netdevConfig.Name;
        networkConfig.Address = [
          "192.168.140.1/24"
          "${config.router.ulaPrefix}:8C::1/64"
          "${config.router.guaPrefix}:8C::1/64"
        ];
      };

      hurricane.matchConfig.Name =
        config.systemd.network.netdevs.hurricane.netdevConfig.Name;
    };
  };
}
