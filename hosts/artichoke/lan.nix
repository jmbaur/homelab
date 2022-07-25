{ lib, inventory, ... }:
let
  mkInternalInterface = network: {
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
      DNS = [ network.hosts.artichoke.ipv4 ];
      EmitNTP = "yes";
      NTP = [ network.hosts.artichoke.ipv4 ];
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
  public = mkInternalInterface inventory.networks.public;
  trusted = mkInternalInterface inventory.networks.trusted;
  iot = mkInternalInterface inventory.networks.iot;
  work = mkInternalInterface inventory.networks.work;
  mgmt = mkInternalInterface inventory.networks.mgmt;
  data = mkInternalInterface inventory.networks.data;
in
{
  systemd.network.networks = {
    lan-master = {
      name = "eth1";
      networkConfig.LinkLocalAddressing = "no";
    };
    mgmt = { name = "lan1"; } // mgmt;
    public = { name = "lan2"; } // public;
    trusted = { name = "lan3"; } // trusted;
    iot = { name = "lan4"; } // iot;
    work = { name = "lan5"; } // work;
    data = { name = "data"; } // data;
  };
}
