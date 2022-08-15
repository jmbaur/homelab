{ lib, ... }: {
  networking = {
    useDHCP = lib.mkForce false;
    hostName = "kale";
    useNetworkd = true;
    firewall.allowedTCPPorts = [ 8080 ];
  };

  systemd.network = {
    links = {
      "10-sfp-sfpplus1" = {
        matchConfig.MACAddress = "d0:63:b4:03:db:6d";
        linkConfig.Name = "sfp-sfpplus1";
      };
      "10-sfp-sfpplus2" = {
        matchConfig.MACAddress = "d0:63:b4:03:db:6e";
        linkConfig.Name = "sfp-sfpplus2";
      };
      "10-sfp-sfpplus3" = {
        matchConfig.MACAddress = "d0:63:b4:03:db:6f";
        linkConfig.Name = "sfp-sfpplus3";
      };
      "10-sfp-sfpplus4" = {
        matchConfig.MACAddress = "d0:63:b4:03:db:70";
        linkConfig.Name = "sfp-sfpplus4";
      };
    };
    networks = {
      mgmt = {
        name = "eth0";
        DHCP = "yes";
        dhcpV4Config.ClientIdentifier = "mac";
      };
    };
  };
}
