{ config, lib, pkgs, ... }:
let
  mkInternalInterface = { name, addrs ? [ ], staticLeases ? [ ] }: {
    matchConfig.Name =
      config.systemd.network.netdevs.${name}.netdevConfig.Name;
    networkConfig = {
      Address = addrs;
      IPv6AcceptRA = false;
      DHCPServer = true;
    };
    dhcpServerConfig = {
      PoolOffset = 100;
      PoolSize = 100;
    };
    extraConfig = lib.concatMapStrings
      (machine: ''
        [DHCPServerStaticLease]
        MACAddress=${machine.macAddr}
        Address=${machine.ipAddr}

      '')
      staticLeases;
  };
in
{
  networking = {
    hostName = "broccoli";
    useDHCP = false;
    useNetworkd = true;
    search = [ "home.arpa" ];
    nat.enable = false;
    firewall.enable = false;
  };

  systemd.network = {
    enable = true;
    netdevs =
      let
        mkVlanNetdev = name: id: {
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
            Local = "any";
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
          IPForward = true;
        };
        dhcpV4Config.UseDNS = false;
      };

      internal = {
        matchConfig.Name = "enp4s0";
        networkConfig = {
          LinkLocalAddressing = "no";
          VLAN = builtins.map
            (name: config.systemd.network.netdevs.${name}.netdevConfig.Name)
            [ "pubwan" "publan" "trusted" "iot" "guest" "mgmt" ];
        };
      };

      pubwan = mkInternalInterface {
        name = "pubwan";
        addrs = [
          "192.168.10.1/24"
          "${config.router.ulaPrefix}:a::1/64"
          "${config.router.guaPrefix}:a::1/64"
        ];
      };

      publan = mkInternalInterface {
        name = "publan";
        addrs = [
          "192.168.20.1/24"
          "${config.router.ulaPrefix}:14::1/64"
          "${config.router.guaPrefix}:14::1/64"
        ];
      };

      trusted = mkInternalInterface {
        name = "trusted";
        addrs = [
          "192.168.30.1/24"
          "${config.router.ulaPrefix}:1e::1/64"
          "${config.router.guaPrefix}:1e::1/64"
        ];
        staticLeases = [
          # asparagus
          { macAddr = "a8:a1:59:2a:04:6d"; ipAddr = "192.168.30.17"; }
        ];
      };

      iot = mkInternalInterface {
        name = "iot";
        addrs = [
          "192.168.40.1/24"
          "${config.router.ulaPrefix}:28::1/64"
          "${config.router.guaPrefix}:28::1/64"
        ];
        staticLeases = [
          # okra
          { macAddr = "5c:80:b6:92:eb:27"; ipAddr = "192.168.40.12"; }
        ];
      };

      guest = mkInternalInterface {
        name = "guest";
        addrs = [
          "192.168.50.1/24"
          "${config.router.ulaPrefix}:32::1/64"
          "${config.router.guaPrefix}:32::1/64"
        ];
      };

      mgmt = mkInternalInterface {
        name = "mgmt";
        addrs = [
          "192.168.88.1/24"
          "${config.router.ulaPrefix}:58::1/64"
          "${config.router.guaPrefix}:58::1/64"
        ];
        staticLeases = [
          # "broccoli-ipmi"
          { macAddr = "00:25:90:f7:32:08"; ipAddr = "192.168.88.201"; }
          # "kale-ipmi"
          { macAddr = "d0:50:99:f7:c4:8d"; ipAddr = "192.168.88.202"; }
          # "kale"
          { macAddr = "d0:50:99:fe:1e:e2"; ipAddr = "192.168.88.7"; }
          # "rhubarb"
          { macAddr = "dc:a6:32:20:50:f2"; ipAddr = "192.168.88.88"; }
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
