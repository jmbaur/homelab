{ lib, inventory, ... }:
let
  domain = "home.arpa";
  mkInternalInterface = network: {
    name = network.hosts.artichoke.interface;
    linkConfig = {
      RequiredForOnline = "no";
    } // lib.optionalAttrs (network.mtu != null) {
      MTUBytes = toString network.mtu;
    };
    networkConfig = {
      Address = [
        "${network.hosts.artichoke.ipv4}/${toString network.ipv4Cidr}"
        "${network.hosts.artichoke.ipv6.gua}/${toString network.ipv6Cidr}"
        "${network.hosts.artichoke.ipv6.ula}/${toString network.ipv6Cidr}"
      ];
      IPv6AcceptRA = false;
      DHCPServer = true;
      IPv6SendRA = true;
    };
    ipv6SendRAConfig = {
      Managed = network.managed;
      OtherInformation = false;
      DNS = "_link_local";
      Domains = [ domain ];
    };
    ipv6Prefixes = map
      (prefix: { ipv6PrefixConfig = { Prefix = prefix; }; })
      (with network; [ networkGuaCidr ]);
    dhcpServerConfig = {
      PoolOffset = 50;
      PoolSize = 200;
      EmitDNS = "yes";
      DNS = "_server_address";
      EmitNTP = "yes";
      NTP = "_server_address";
      SendOption = [
        "15:string:${domain}"
      ] ++ lib.optional (network.mtu != null) "26:uint16:${toString network.mtu}";
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
  public = mkInternalInterface inventory.networks.public;
  trusted = mkInternalInterface inventory.networks.trusted;
  iot = mkInternalInterface inventory.networks.iot;
  work = mkInternalInterface inventory.networks.work;
  mgmt = mkInternalInterface inventory.networks.mgmt;
  data = mkInternalInterface inventory.networks.data;
in
{
  systemd.network.networks = {
    lan-master = { name = "eth1"; linkConfig.RequiredForOnline = "no"; };
    mgmt = lib.recursiveUpdate mgmt { networkConfig.BindCarrier = "eth1"; };
    public = lib.recursiveUpdate public { networkConfig.BindCarrier = "eth1"; };
    trusted = lib.recursiveUpdate trusted { networkConfig.BindCarrier = "eth1"; };
    iot = lib.recursiveUpdate iot { networkConfig.BindCarrier = "eth1"; };
    work = lib.recursiveUpdate work { networkConfig.BindCarrier = "eth1"; };
    data = data;
  };
}
