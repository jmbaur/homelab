{ config, lib, pkgs, ... }:
let
  guaPrefix = "2001:470:f001";
  ulaPrefix = "fd82:f21d:118d";
in
{
  networking = {
    hostName = "broccoli";
    useDHCP = false;
    useNetworkd = true;
    nameservers = [ "127.0.0.1" "::1" ];
    search = [ "home.arpa" ];
    stevenBlackHosts.enable = true;
    nat.enable = false;
    firewall.enable = false;

    wireguard = {
      enable = true;
      interfaces.wg-trusted = {
        listenPort = 51830;
        ips = [
          "192.168.130.1/24"
          "${ulaPrefix}:82::1/64"
          "${guaPrefix}:82::1/64"
        ];
        privateKeyFile = "/run/secrets/wg-trusted";
        peers = [ ];
      };
      interfaces.wg-iot = {
        listenPort = 51840;
        ips = [
          "192.168.140.1/24"
          "${ulaPrefix}:8C::1/64"
          "${guaPrefix}:8C::1/64"
        ];
        privateKeyFile = "/run/secrets/wg-iot";
        peers = [ ];
      };
    };
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

        hurricane = {
          netdevConfig = {
            Name = "hurricane";
            Kind = "sit";
            MTUBytes = "1480";
          };
          tunnelConfig = {
            Local = "dhcp4";
            Remote = "66.220.18.42";
            TTL = 255;
          };
        };
      };

    networks = {
      wan = {
        matchConfig.Name = "enp0s20f0";
        networkConfig = {
          Tunnel = "hurricane";
          DHCP = "yes"; # TODO(jared): setup run hooks
        };
      };

      vlanMaster = {
        matchConfig.Name = "enp4s0";
        networkConfig.VLAN = builtins.map
          (name: config.systemd.network.netdevs.${name}.netdevConfig.Name)
          [ "pubwan" "publan" "trusted" "iot" "guest" "mgmt" ];
      };

      pubwan = {
        matchConfig.Name = "pubwan";
        networkConfig.DHCP = "no";
        addresses = [
          { addressConfig.Address = "192.168.10.1/24"; }
          { addressConfig.Address = "${ulaPrefix}:a::1/64"; }
          { addressConfig.Address = "${guaPrefix}:a::1/64"; }
        ];
      };

      publan = {
        matchConfig.Name = "publan";
        networkConfig.DHCP = "no";
        addresses = [
          { addressConfig.Address = "192.168.20.1/24"; }
          { addressConfig.Address = "${ulaPrefix}:14::1/64"; }
          { addressConfig.Address = "${guaPrefix}:14::1/64"; }
        ];
      };

      trusted = {
        matchConfig.Name = "trusted";
        networkConfig.DHCP = "no";
        addresses = [
          { addressConfig.Address = "192.168.30.1/24"; }
          { addressConfig.Address = "${ulaPrefix}:1e::1/64"; }
          { addressConfig.Address = "${guaPrefix}:1e::1/64"; }
        ];
      };

      iot = {
        matchConfig.Name = "iot";
        networkConfig.DHCP = "no";
        addresses = [
          { addressConfig.Address = "192.168.40.1/24"; }
          { addressConfig.Address = "${ulaPrefix}:28::1/64"; }
          { addressConfig.Address = "${guaPrefix}:28::1/64"; }
        ];
      };

      guest = {
        matchConfig.Name = "guest";
        networkConfig.DHCP = "no";
        addresses = [
          { addressConfig.Address = "192.168.50.1/24"; }
          { addressConfig.Address = "${ulaPrefix}:32::1/64"; }
          { addressConfig.Address = "${guaPrefix}:32::1/64"; }
        ];
      };

      mgmt = {
        matchConfig.Name = "mgmt";
        networkConfig.DHCP = "no";
        addresses = [
          { addressConfig.Address = "192.168.88.1/24"; }
          { addressConfig.Address = "${ulaPrefix}:58::1/64"; }
          { addressConfig.Address = "${guaPrefix}:58::1/64"; }
        ];
      };

      hurricane = {
        matchConfig.Name = "hurricane";
        networkConfig = {
          Address = "2001:470:c:9::2/64";
          Gateway = "2001:470:c:9::1/64";
        };
      };
    };
  };
}




# interfaces = {
#   pubwan = {
#     ipv4.addresses = [{ address = "192.168.10.1"; prefixLength = 24; }];
#     ipv6.addresses = [
#       { address = "${ulaPrefix}:a::1"; prefixLength = 64; }
#       { address = "${guaPrefix}:a::1"; prefixLength = 64; }
#     ];
#   };
#   publan = {
#     ipv4.addresses = [{ address = "192.168.20.1"; prefixLength = 24; }];
#     ipv6.addresses = [
#       { address = "${ulaPrefix}:14::1"; prefixLength = 64; }
#       { address = "${guaPrefix}:14::1"; prefixLength = 64; }
#     ];
#   };
#   trusted = {
#     ipv4.addresses = [{ address = "192.168.30.1"; prefixLength = 24; }];
#     ipv6.addresses = [
#       { address = "${ulaPrefix}:1e::1"; prefixLength = 64; }
#       { address = "${guaPrefix}:1e::1"; prefixLength = 64; }
#     ];
#   };
#   iot = {
#     ipv4.addresses = [{ address = "192.168.40.1"; prefixLength = 24; }];
#     ipv6.addresses = [
#       { address = "${ulaPrefix}:28::1"; prefixLength = 64; }
#       { address = "${guaPrefix}:28::1"; prefixLength = 64; }
#     ];
#   };
#   guest = {
#     ipv4.addresses = [{ address = "192.168.50.1"; prefixLength = 24; }];
#     ipv6.addresses = [
#       { address = "${ulaPrefix}:32::1"; prefixLength = 64; }
#       { address = "${guaPrefix}:32::1"; prefixLength = 64; }
#     ];
#   };
#   mgmt = {
#     ipv4.addresses = [{ address = "192.168.88.1"; prefixLength = 24; }];
#     ipv6.addresses = [
#       { address = "${ulaPrefix}:58::1"; prefixLength = 64; }
#       { address = "${guaPrefix}:58::1"; prefixLength = 64; }
#     ];
#   };
# };
