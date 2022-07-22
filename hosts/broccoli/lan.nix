{ config, lib, pkgs, secrets, inventory, ... }:
let
  mkInternalInterface = network: {
    netdev = {
      netdevConfig = { Name = network.name; Kind = "vlan"; };
      vlanConfig.Id = network.id;
    };
    network = {
      name = network.name;
      networkConfig = {
        Address = [
          "${network.hosts.broccoli.ipv4}/${toString network.ipv4Cidr}"
          "${network.hosts.broccoli.ipv6.gua}/${toString network.ipv6Cidr}"
          "${network.hosts.broccoli.ipv6.ula}/${toString network.ipv6Cidr}"
        ];
        IPv6AcceptRA = false;
        DHCPServer = true;
        IPv6SendRA = true;
      };
      ipv6SendRAConfig = {
        Managed = network.managed;
        OtherInformation = false;
        DNS = "_link_local";
        Domains = [ "home.arpa" ];
      };
      ipv6Prefixes = map
        (prefix: { ipv6PrefixConfig = { Prefix = prefix; }; })
        (with network; [ networkGuaCidr ]);
      dhcpServerConfig = {
        PoolOffset = 50;
        PoolSize = 200;
        # TODO(jared): When https://github.com/systemd/systemd/pull/22332 is
        # released, use DNS="_server_address".
        EmitDNS = "yes";
        DNS = [ network.hosts.broccoli.ipv4 ];
        EmitNTP = "yes";
        NTP = [ network.hosts.broccoli.ipv4 ];
        SendOption = [ "15:string:home.arpa" ];
      };
      dhcpServerStaticLeases = lib.flatten
        (lib.mapAttrsToList
          (_: host: {
            dhcpServerStaticLeaseConfig = {
              MACAddress = host.mac;
              Address = host.ipv4;
            };
          })
          (lib.filterAttrs (_: host: host.dhcp) network.hosts));
    };
  };
  pubwan = mkInternalInterface inventory.networks.pubwan;
  publan = mkInternalInterface inventory.networks.publan;
  trusted = mkInternalInterface inventory.networks.trusted;
  iot = mkInternalInterface inventory.networks.iot;
  work = mkInternalInterface inventory.networks.work;
  mgmt = mkInternalInterface inventory.networks.mgmt;
in
{
  networking = {
    hostName = "broccoli";
    useDHCP = false;
    useNetworkd = true;
    nat.enable = false;
    firewall.enable = false;
    nameservers = [ "127.0.0.1" "::1" ];
  };

  services.resolved = {
    enable = true;
    extraConfig = ''
      DNSStubListener=no
    '';
  };

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
    name = "enp0s20f3";
    networkConfig.LinkLocalAddressing = "no";
    vlan = map
      (name: config.systemd.network.netdevs.${name}.netdevConfig.Name)
      [ "pubwan" "publan" "trusted" "iot" "work" "mgmt" ];
  };
}
