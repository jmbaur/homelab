{ config, pkgs, ... }: {
  services.dhcpd6 = {
    enable = true;
    interfaces = with config.networking.interfaces; [ mgmt.name ];
    machines = [
      # {
      #   hostName = "broccoli-ipmi";
      #   ethernetAddress = "00:25:90:f7:32:08";
      #   ipAddress = "fd82:f21d:118d:58::c9";
      # }
      # {
      #   hostName = "kale-ipmi";
      #   ethernetAddress = "d0:50:99:f7:c4:8d";
      #   ipAddress = "fd82:f21d:118d:58::ca";
      # }
      # {
      #   hostName = "kale";
      #   ethernetAddress = "d0:50:99:fe:1e:e2";
      #   ipAddress = "fd82:f21d:118d:58::7";
      # }
      # {
      #   hostName = "rhubarb";
      #   ethernetAddress = "dc:a6:32:20:50:f2";
      #   ipAddress = "fd82:f21d:118d:58::58";
      # }
    ];
    extraConfig = ''
      ddns-update-style none;
      option dhcp6.domain-search "home.arpa";

      subnet6 fd82:f21d:118d:58::/64 {
        range6 fd82:f21d:118d:58::64 fd82:f21d:118d:58::c8;
      }

      host kale {
        hardware ethernet d0:50:99:fe:1e:e2;
        fixed-address6 fd82:f21d:118d:58::7;
      }
    '';
  };
}
