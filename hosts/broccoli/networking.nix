{ config, lib, pkgs, ... }: {
  networking = {
    hostName = "broccoli";
    useDHCP = false;
    useNetworkd = true;
    nat.enable = false;
    firewall.enable = false;
  };

  services.resolved.enable = false;

  systemd.network.enable = true;

  systemd.network.netdevs =
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

  systemd.network.networks =
    let
      mkInternalInterface = { name, staticLeases ? [ ] }:
        let
          ipv4ThirdOctet =
            config.systemd.network.netdevs.${name}.vlanConfig.Id;
          ipv6FourthHextet = lib.toHexString ipv4ThirdOctet;
          ipv4Addr = "192.168.${toString ipv4ThirdOctet}.1";
          ipv4Cidr = "${ipv4Addr}/24";
          networkGuaPrefix = "${config.router.guaPrefix}:${ipv6FourthHextet}";
          networkUlaPrefix = "${config.router.ulaPrefix}:${ipv6FourthHextet}";
          guaNetwork = "${networkGuaPrefix}::/64";
          ulaNetwork = "${networkUlaPrefix}::/64";
          ipv6GuaAddr = "${networkGuaPrefix}::1/64";
          ipv6UlaAddr = "${networkUlaPrefix}::1/64";
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
            # released, use DNS="_server_address".
            DNS = ipv4Addr;
            SendOption = [ "15:string:home.arpa" ];
          };
          dhcpServerStaticLeases = map
            (lease: {
              dhcpServerStaticLeaseConfig = lease;
            })
            staticLeases;
        };
    in
    {
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
          { MACAddress = "a8:a1:59:2a:04:6d"; Address = "192.168.30.17"; }
        ];
      };
      iot = mkInternalInterface {
        name = "iot";
        staticLeases = [
          # okra
          { MACAddress = "5c:80:b6:92:eb:27"; Address = "192.168.40.12"; }
        ];
      };
      guest = mkInternalInterface { name = "guest"; };
      mgmt = mkInternalInterface {
        name = "mgmt";
        staticLeases = [
          # broccoli-ipmi
          { MACAddress = "00:25:90:f7:32:08"; Address = "192.168.88.201"; }
          # kale-ipmi
          { MACAddress = "d0:50:99:f7:c4:8d"; Address = "192.168.88.202"; }
          # kale
          { MACAddress = "d0:50:99:fe:1e:e2"; Address = "192.168.88.7"; }
          # rhubarb
          { MACAddress = "dc:a6:32:20:50:f2"; Address = "192.168.88.88"; }
        ];
      };

      hurricane.matchConfig.Name =
        config.systemd.network.netdevs.hurricane.netdevConfig.Name;
    };
}
