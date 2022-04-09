{ config, lib, pkgs, ... }:
let
  guaPrefix = "2001:470:f001";
  ulaPrefix = "fd82:f21d:118d";
in
{
  networking = {
    hostName = "broccoli";
    useDHCP = false;
    nameservers = [ "127.0.0.1" "::1" ];
    search = [ "home.arpa" ];
    stevenBlackHosts.enable = true;
    nat.enable = false;
    firewall.enable = false;
    defaultGateway6.address = "2001:470:c:9::1";
    defaultGateway6.interface = "hurricane";
    sits.hurricane = {
      dev = "enp0s20f0";
      ttl = 255;
      remote = "66.220.18.42";
    };
    vlans = {
      pubwan = { id = 10; interface = "enp4s0"; };
      publan = { id = 20; interface = "enp4s0"; };
      trusted = { id = 30; interface = "enp4s0"; };
      iot = { id = 40; interface = "enp4s0"; };
      guest = { id = 50; interface = "enp4s0"; };
      mgmt = { id = 88; interface = "enp4s0"; };
    };
    interfaces = {
      enp0s20f0.useDHCP = true;
      hurricane = {
        ipv6.addresses = [{ address = "2001:470:c:9::2"; prefixLength = 64; }];
      };
      enp4s0 = {
        ipv4.addresses = lib.mkForce [ ];
        ipv6.addresses = lib.mkForce [ ];
      };
      pubwan = {
        ipv4.addresses = [{ address = "192.168.10.1"; prefixLength = 24; }];
        ipv6.addresses = [
          { address = "${ulaPrefix}:a::1"; prefixLength = 64; }
          { address = "${guaPrefix}:a::1"; prefixLength = 64; }
        ];
      };
      publan = {
        ipv4.addresses = [{ address = "192.168.20.1"; prefixLength = 24; }];
        ipv6.addresses = [
          { address = "${ulaPrefix}:14::1"; prefixLength = 64; }
          { address = "${guaPrefix}:14::1"; prefixLength = 64; }
        ];
      };
      trusted = {
        ipv4.addresses = [{ address = "192.168.30.1"; prefixLength = 24; }];
        ipv6.addresses = [
          { address = "${ulaPrefix}:1e::1"; prefixLength = 64; }
          { address = "${guaPrefix}:1e::1"; prefixLength = 64; }
        ];
      };
      iot = {
        ipv4.addresses = [{ address = "192.168.40.1"; prefixLength = 24; }];
        ipv6.addresses = [
          { address = "${ulaPrefix}:28::1"; prefixLength = 64; }
          { address = "${guaPrefix}:28::1"; prefixLength = 64; }
        ];
      };
      guest = {
        ipv4.addresses = [{ address = "192.168.50.1"; prefixLength = 24; }];
        ipv6.addresses = [
          { address = "${ulaPrefix}:32::1"; prefixLength = 64; }
          { address = "${guaPrefix}:32::1"; prefixLength = 64; }
        ];
      };
      mgmt = {
        ipv4.addresses = [{ address = "192.168.88.1"; prefixLength = 24; }];
        ipv6.addresses = [
          { address = "${ulaPrefix}:58::1"; prefixLength = 64; }
          { address = "${guaPrefix}:58::1"; prefixLength = 64; }
        ];
      };
    };
    wireguard = {
      enable = true;
      interfaces.wg-trusted = {
        listenPort = 51820;
        ips = [
          "192.168.130.1/24"
          "${ulaPrefix}:82::1/64"
          "${guaPrefix}:82::1/64"
        ];
        privateKeyFile = "/run/secrets/wg-trusted";
        peers = [ ];
      };
      interfaces.wg-iot = {
        listenPort = 51820;
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
}
