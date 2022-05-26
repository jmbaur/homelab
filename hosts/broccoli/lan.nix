{ config, lib, pkgs, secrets, inventory, ... }:
let
  mkInternalInterface = network: {
    netdev = {
      netdevConfig = { Name = network.name; Kind = "vlan"; };
      vlanConfig.Id = network.id;
    };
    network = {
      matchConfig.Name = network.name;
      networkConfig = {
        Address =
          map (ip: "${ip}/${toString network.ipv4Cidr}") network.hosts.broccoli.ipv4
          ++
          map (ip: "${ip}/${toString network.ipv6Cidr}") network.hosts.broccoli.ipv6;
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
        (with network; [ networkGuaCidr networkUlaCidr ]);
      dhcpServerConfig = {
        PoolOffset = 50;
        PoolSize = 200;
        # TODO(jared): When https://github.com/systemd/systemd/pull/22332 is
        # released, use DNS="_server_address".
        DNS = network.hosts.broccoli.ipv4;
        SendOption = [ "15:string:${network.domain}" ];
      };
      dhcpServerStaticLeases = lib.flatten
        (lib.mapAttrsToList
          (_: host:
            (if host.dhcp then
              (map
                (ipAddr: {
                  dhcpServerStaticLeaseConfig = {
                    MACAddress = host.mac;
                    Address = ipAddr;
                  };
                })
                host.ipv4) else [ ]))
          inventory.${network.name}.hosts);
    };
  };
  pubwan = mkInternalInterface inventory.pubwan;
  publan = mkInternalInterface inventory.publan;
  trusted = mkInternalInterface inventory.trusted;
  iot = mkInternalInterface inventory.iot;
  work = mkInternalInterface inventory.work;
  mgmt = mkInternalInterface inventory.mgmt;
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

  systemd.network.enable = true;

  systemd.network.netdevs = {
    pubwan = pubwan.netdev;
    publan = publan.netdev;
    trusted = trusted.netdev;
    iot = iot.netdev;
    work = work.netdev;
    mgmt = mgmt.netdev;
  };

  systemd.network.networks = {
    pubwan = pubwan.network;
    publan = publan.network;
    trusted = trusted.network;
    iot = iot.network;
    work = work.network;
    mgmt = mgmt.network;
  };

  systemd.network.networks.trunk = {
    matchConfig.Name = "enp4s0";
    networkConfig = {
      LinkLocalAddressing = "no";
      VLAN = map
        (name: config.systemd.network.netdevs.${name}.netdevConfig.Name)
        ([ "pubwan" "publan" "trusted" "iot" "work" "mgmt" ]);
    };
  };
}
