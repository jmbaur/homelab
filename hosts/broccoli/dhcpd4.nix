{ config, pkgs, ... }: {
  services.atftpd.enable = true;
  systemd.activationScripts.netboot.text = ''
    ln -sfT ${pkgs.netbootxyz-efi} ${config.services.atftpd.root}/netboot.xyz.efi
  '';
  services.dhcpd4 = {
    enable = true;
    interfaces = [ "trusted" "iot" "guest" "mgmt" ];
    machines = [
      {
        ipAddress = "192.168.88.201";
        hostName = "broccoli-ipmi";
        ethernetAddress = "00:25:90:46:38:3f";
      }
      {
        ipAddress = "192.168.88.202";
        hostName = "kale-ipmi";
        ethernetAddress = "d0:50:99:f7:c4:8d";
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
        class "pxeclients"{
          match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
          next-server 192.168.30.1;
          filename "netboot.xyz.efi";
        }
        class "httpclients" {
          match if substring (option vendor-class-identifier, 0, 10) = "HTTPClient";
          option vendor-class-identifier "HTTPClient";
          filename "https://boot.netboot.xyz/ipxe/netboot.xyz.efi";
        }
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
