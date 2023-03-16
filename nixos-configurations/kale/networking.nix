{ config, lib, ... }:
let
  wg = import ../../nixos-modules/mesh-network/inventory.nix;
in
{
  networking = {
    useDHCP = lib.mkForce false;
    hostName = "kale";
  };

  custom.wg-mesh = {
    enable = true;
    peers.okra = { };
    peers.www.extraConfig = {
      Endpoint = "www.jmbaur.com:51820";
      PersistentKeepalive = 25;
    };
    firewall.ips."${wg.okra.ip}".allowedTCPPorts = [ config.services.prometheus.exporters.node.port 19531 ];
    firewall.ips."${wg.www.ip}" = {
      # nfs
      allowedTCPPorts = [ 111 2049 ];
      allowedUDPPorts = [ 111 2049 ];
    };
  };

  systemd.network = {
    enable = true;
    links = {
      "10-sfpplus1" = {
        matchConfig.MACAddress = "d0:63:b4:03:db:6d";
        linkConfig.Name = "sfpplus1";
      };
      "10-sfpplus2" = {
        matchConfig.MACAddress = "d0:63:b4:03:db:6e";
        linkConfig.Name = "sfpplus2";
      };
      "10-sfpplus3" = {
        matchConfig.MACAddress = "d0:63:b4:03:db:6f";
        linkConfig.Name = "sfpplus3";
      };
      "10-sfpplus4" = {
        matchConfig.MACAddress = "d0:63:b4:03:db:70";
        linkConfig.Name = "sfpplus4";
      };
    };

    networks.ether = {
      name = "eth0";
      DHCP = "yes";
      dhcpV4Config.ClientIdentifier = "mac";
    };
  };
}
