{ config, lib, ... }: {
  networking = {
    useDHCP = lib.mkForce false;
    hostName = "kale";
    firewall = {
      interfaces.eth0.allowedTCPPorts = lib.mkForce [ config.services.prometheus.exporters.node.port ];
      interfaces.www.allowedTCPPorts = lib.mkForce [ 19531 ];
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
    networks = {
      mgmt = {
        name = "eth0";
        DHCP = "yes";
        dhcpV4Config.ClientIdentifier = "mac";
      };
    };
  };
}
