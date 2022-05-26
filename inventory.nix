{ lib }:
# NOTE: None of this uses math to calculate network CIDR masks and such, so it
# is all assumed to have clean CIDR masks such as /24 for ipv4 and /64 for
# ipv6.
# NOTE: The parameters of this function, guaPrefix and ulaPrefix, are of the
# form X:X:X where X is an IPv6 hextet. Each prefix is a /48 network prefix to
# prepend to the remaining 80 bits of an IPv6 address.

let
  # NOTE: Wrapping nixpkgs toHexString to follow RFC 5952's recommendation for
  # IPv6 addresses to be in lower case.
  toHexString = i: lib.toLower (lib.toHexString i);
  mkIpv4Addr = prefix: thirdOctet: fourthOctet: "${prefix}.${toString thirdOctet}.${toString fourthOctet}";
  mkIpv6Addr = prefix: fourthHextet: lastHextet: "${prefix}:${fourthHextet}::${lastHextet}";
in

{ guaPrefix
, ulaPrefix
, tld
}:
let
  mkHost = networkId: { dhcp ? false, mac ? null, lastBit }: {
    inherit dhcp mac;
    ipv4 = [ (mkIpv4Addr "192.168" networkId lastBit) ];
    ipv6 = [
      (mkIpv6Addr guaPrefix (toHexString networkId) (toHexString lastBit))
      (mkIpv6Addr ulaPrefix (toHexString networkId) (toHexString lastBit))
    ];
  };
  mkNetwork = { name, id, hosts }:
    let
      mkNetworkHost = mkHost id;
      ipv4Cidr = 24;
      ipv6Cidr = 64;
      networkGuaPrefix = "${guaPrefix}:${toHexString id}";
      networkUlaPrefix = "${ulaPrefix}:${toHexString id}";
      networkGuaCidr = "${networkGuaPrefix}::/${toString ipv6Cidr}";
      networkUlaCidr = "${networkUlaPrefix}::/${toString ipv6Cidr}";
    in
    {
      inherit
        name
        id
        ipv4Cidr
        ipv6Cidr
        networkGuaPrefix
        networkUlaPrefix
        networkGuaCidr
        networkUlaCidr;
      domain = "${name}.${tld}";
      hosts = lib.mapAttrs
        (_: host: mkNetworkHost host)
        hosts;
    };
in
{
  mgmt = mkNetwork {
    name = "mgmt";
    id = 88;
    hosts = {
      broccoli.lastBit = 1;
      switch0.lastBit = 2;
      switch1.lastBit = 3;
      ap0.lastBit = 4;
      broccoli-ipmi = { lastBit = 50; dhcp = true; mac = "00:25:90:f7:32:08"; };
      kale-ipmi = { lastBit = 51; dhcp = true; mac = "d0:50:99:f7:c4:8d"; };
      kale = { lastBit = 52; dhcp = true; mac = "d0:50:99:fe:1e:e2"; };
      rhubarb = { lastBit = 53; dhcp = true; mac = "dc:a6:32:20:50:f2"; };
      asparagus = { lastBit = 54; dhcp = true; mac = "a8:a1:59:2a:04:6d"; };
    };
  };
  pubwan = mkNetwork {
    name = "pubwan";
    id = 10;
    hosts.broccoli.lastBit = 1;
  };
  publan = mkNetwork {
    name = "publan";
    id = 20;
    hosts.broccoli.lastBit = 1;
  };
  trusted = mkNetwork {
    name = "trusted";
    id = 30;
    hosts = {
      broccoli.lastBit = 1;
      asparagus = { lastBit = 50; dhcp = true; mac = "e4:1d:2d:7f:1a:d0"; };
      okra = { lastBit = 51; dhcp = true; mac = "5c:80:b6:92:eb:27"; };
    };
  };
  iot = mkNetwork {
    name = "iot";
    id = 40;
    hosts.broccoli.lastBit = 1;
  };
  work = mkNetwork {
    name = "work";
    id = 50;
    hosts.broccoli.lastBit = 1;
  };
}
