{ config, lib, pkgs, ... }:
let hosts = import ../hosts.nix;
in
{
  services.dhcpd4 = {
    enable = true;
    interfaces = [ "mgmt" "lab" "guest" "iot" ];
    machines = lib.attrsets.attrValues hosts.hosts;
    extraConfig = with hosts; ''
      ddns-update-style none;

      default-lease-time 86400;
      max-lease-time 86400;

      subnet 192.168.1.0 netmask 255.255.255.0 {
        option routers 192.168.1.1;
        option broadcast-address 192.168.1.255;
        option subnet-mask 255.255.255.0;
        option domain-name-servers 192.168.1.1;
        range 192.168.1.100 192.168.1.200;

        allow booting;
        next-server 192.168.1.1;
        option bootfile-name "netboot.xyz.kpxe";

        option domain-search "lan";
        option domain-name "lan";
      }

      subnet 192.168.2.0 netmask 255.255.255.0 {
        option routers 192.168.2.1;
        option broadcast-address 192.168.2.255;
        option subnet-mask 255.255.255.0;
        option domain-name-servers 192.168.2.1;
        range 192.168.2.100 192.168.2.200;

        allow booting;
        next-server 192.168.2.1;
        option bootfile-name "netboot.xyz.kpxe";

        option domain-search "lan";
        option domain-name "lan";
      }

      subnet 192.168.3.0 netmask 255.255.255.0 {
        option routers 192.168.3.1;
        option broadcast-address 192.168.3.255;
        option subnet-mask 255.255.255.0;
        option domain-name-servers 192.168.3.1;
        range 192.168.3.100 192.168.3.200;

        option domain-search "lan";
        option domain-name "lan";
      }

      subnet 192.168.4.0 netmask 255.255.255.0 {
        option routers 192.168.4.1;
        option broadcast-address 192.168.4.255;
        option subnet-mask 255.255.255.0;
        option domain-name-servers 192.168.4.1;
        range 192.168.4.100 192.168.4.200;

        option domain-search "lan";
        option domain-name "lan";
      }
    '';
  };
}
