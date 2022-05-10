{ config, pkgs, ... }: {
  services.dhcpd6 = {
    enable = true;
    interfaces = [ config.systemd.network.networks.mgmt.matchConfig.Name ];
    machines = [
      {
        hostName = "broccoli-ipmi";
        ethernetAddress = "00:25:90:f7:32:08";
        ipAddress = "${config.router.ulaPrefix}:58::c9";
      }
      {
        hostName = "kale-ipmi";
        ethernetAddress = "d0:50:99:f7:c4:8d";
        ipAddress = "${config.router.ulaPrefix}:58::ca";
      }
      {
        hostName = "kale";
        ethernetAddress = "d0:50:99:fe:1e:e2";
        ipAddress = "${config.router.ulaPrefix}:58::7";
      }
      {
        hostName = "rhubarb";
        ethernetAddress = "dc:a6:32:20:50:f2";
        ipAddress = "${config.router.ulaPrefix}:58::58";
      }
    ];
    extraConfig = ''
      ddns-update-style none;
      option dhcp6.domain-search "home.arpa";

      subnet6 ${config.router.ulaPrefix}:58::/64 {
        range6 ${config.router.ulaPrefix}:58::64 ${config.router.ulaPrefix}:58::c8;
      }
    '';
  };
}
