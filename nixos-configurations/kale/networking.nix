{ config, lib, ... }: {
  networking = {
    useDHCP = lib.mkForce false;
    firewall.interfaces.eth0.allowedTCPPorts = [ 22 ];
  };

  custom.wg-mesh = {
    enable = true;
    peers.carrot = { };
    peers.www = {
      dnsName = "www.jmbaur.com";
      extraConfig.PersistentKeepalive = 25;
    };
    firewall.carrot.allowedTCPPorts = [ config.services.prometheus.exporters.node.port 19531 ];
    firewall.www =
      # nfs
      {
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
