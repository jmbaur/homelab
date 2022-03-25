{ config, pkgs, ... }: {
  services.atftpd.enable = true;
  systemd.tmpfiles.rules = [
    "L+ ${config.services.atftpd.root}/netboot.xyz.efi 644 root root - ${pkgs.netbootxyz-efi}"
  ];
  services.dhcpd4 = {
    enable = true;
    interfaces = with config.networking.interfaces; [ trusted.name iot.name guest.name mgmt.name ];
    machines = [
      {
        ipAddress = "192.168.88.201";
        hostName = "broccoli-ipmi";
        ethernetAddress = "00:25:90:f7:32:08";
      }
      {
        ipAddress = "192.168.88.202";
        hostName = "kale-ipmi";
        ethernetAddress = "d0:50:99:f7:c4:8d";
      }
      {
        ethernetAddress = "d0:50:99:fe:1e:e2";
        hostName = "kale";
        ipAddress = "192.168.88.7";
      }
      {
        hostName = "rhubarb";
        ipAddress = "192.168.88.88";
        ethernetAddress = "dc:a6:32:20:50:f2";
      }
      {
        hostName = "asparagus";
        ipAddress = "192.168.30.17";
        ethernetAddress = "1c:69:7a:64:45:b2";
      }
    ];
    extraConfig = ''
      ddns-update-style none;
      option domain-search "home.arpa";
      option domain-name "home.arpa";

      subnet 192.168.30.0 netmask 255.255.255.0 {
        range 192.168.30.100 192.168.30.200;
        option routers 192.168.30.1;
        option broadcast-address 192.168.30.255;
        option subnet-mask 255.255.255.0;
        option domain-name-servers 192.168.30.1;
        next-server 192.168.30.1;
        filename "netboot.xyz.efi";
      }

      subnet 192.168.40.0 netmask 255.255.255.0 {
        range 192.168.40.100 192.168.40.200;
        option routers 192.168.40.1;
        option broadcast-address 192.168.40.255;
        option subnet-mask 255.255.255.0;
        option domain-name-servers 192.168.40.1;
      }

      subnet 192.168.50.0 netmask 255.255.255.0 {
        range 192.168.50.100 192.168.50.200;
        option routers 192.168.50.1;
        option broadcast-address 192.168.50.255;
        option subnet-mask 255.255.255.0;
        option domain-name-servers 192.168.50.1;
      }

      subnet 192.168.88.0 netmask 255.255.255.0 {
        range 192.168.88.100 192.168.88.200;
        option routers 192.168.88.1;
        option broadcast-address 192.168.88.255;
        option subnet-mask 255.255.255.0;
        option domain-name-servers 192.168.88.1;
      }
    '';
  };
}
