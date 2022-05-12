{ config, lib, pkgs, ... }:
let
  mkInternalInterface =
    { name, staticLeases ? [ ] }:
    let
      ipv4ThirdOctet =
        config.systemd.network.netdevs.${name}.vlanConfig.Id;
      ipv6FourthHextet = lib.toHexString ipv4ThirdOctet;
      ipv4Addr = "192.168.${toString ipv4ThirdOctet}.1";
      ipv4Cidr = "${ipv4Addr}/24";
      guaPrefix = "${config.router.guaPrefix}:${ipv6FourthHextet}";
      ulaPrefix = "${config.router.ulaPrefix}:${ipv6FourthHextet}";
      guaNetwork = "${guaPrefix}::/64";
      ulaNetwork = "${ulaPrefix}::/64";
      ipv6GuaAddr = "${guaPrefix}::1/64";
      ipv6UlaAddr = "${ulaPrefix}::1/64";
    in
    {
      matchConfig.Name =
        config.systemd.network.netdevs.${name}.netdevConfig.Name;
      networkConfig = {
        Address = [ ipv4Cidr ipv6GuaAddr ipv6UlaAddr ];
        IPv6AcceptRA = false;
        DHCPServer = true;
        IPv6SendRA = true;
      };
      ipv6SendRAConfig = {
        DNS = "_link_local";
        Domains = [ "home.arpa" ];
      };
      ipv6Prefixes = map
        (prefix: { ipv6PrefixConfig = { Prefix = prefix; }; })
        [ guaNetwork ulaNetwork ];
      dhcpServerConfig = {
        PoolOffset = 100;
        PoolSize = 100;
        # TODO(jared): When https://github.com/systemd/systemd/pull/22332 is
        # released, switch to DNS="_server_address".
        DNS = ipv4Addr;
      };
      extraConfig = (lib.concatMapStrings
        (machine: ''
          [DHCPServerStaticLease]
          MACAddress=${machine.macAddr}
          Address=${machine.ipAddr}

        '')
        staticLeases);
    };
in
{
  networking = {
    hostName = "broccoli";
    useDHCP = false;
    useNetworkd = true;
    nat.enable = false;
    firewall.enable = false;
  };

  services.resolved.enable = false;

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
          LinkLocalAddressing = "no";
          IPForward = true;
        };
        dhcpV4Config = {
          UseDNS = false;
          UseDomains = false;
        };
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

      pubwan = mkInternalInterface { name = "pubwan"; };

      publan = mkInternalInterface { name = "publan"; };

      trusted = mkInternalInterface {
        name = "trusted";
        staticLeases = [
          # asparagus
          { macAddr = "a8:a1:59:2a:04:6d"; ipAddr = "192.168.30.17"; }
        ];
      };

      iot = mkInternalInterface {
        name = "iot";
        staticLeases = [
          # okra
          { macAddr = "5c:80:b6:92:eb:27"; ipAddr = "192.168.40.12"; }
        ];
      };

      guest = mkInternalInterface { name = "guest"; };

      mgmt = mkInternalInterface {
        name = "mgmt";
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
