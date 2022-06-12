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
  mkIPv4Addr = prefix: thirdOctet: fourthOctet: "${prefix}.${toString thirdOctet}.${toString fourthOctet}";
  mkIPv6Addr = prefix: fourthHextet: lastHextet: "${prefix}:${fourthHextet}::${lastHextet}";
in

{ guaPrefix
, ulaPrefix
, tld
}:
let
  mkHost = networkId: name: { dhcp ? false
                            , mac ? null
                            , wgPeer ? false
                            , publicKey ? null
                            , lastBit
                            }: {
    inherit name dhcp mac wgPeer publicKey;
    ipv4 = [ (mkIPv4Addr "192.168" networkId lastBit) ];
    ipv6 = [
      (mkIPv6Addr guaPrefix (toHexString networkId) (toHexString lastBit))
      (mkIPv6Addr ulaPrefix (toHexString networkId) (toHexString lastBit))
    ];
  };
  mkNetwork = name: { id, hosts }:
    let
      mkNetworkHost = mkHost id;
      ipv4Cidr = 24;
      ipv6Cidr = 64;
      networkIPv4 = mkIPv4Addr "192.168" id 0;
      networkIPv4Cidr = "${networkIPv4}/${toString ipv4Cidr}";
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
        networkIPv4
        networkIPv4Cidr
        networkGuaPrefix
        networkUlaPrefix
        networkGuaCidr
        networkUlaCidr;
      domain = "${name}.${tld}";
      hosts = lib.mapAttrs
        (name: hostInfo: mkNetworkHost name hostInfo)
        hosts;
    };
in
lib.mapAttrs (name: networkInfo: mkNetwork name networkInfo) {
  mgmt = {
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
      asparagus = { lastBit = 54; dhcp = true; mac = "e4:1d:2d:7f:1a:d0"; };
    };
  };
  pubwan = {
    id = 10;
    hosts.broccoli.lastBit = 1;
  };
  publan = {
    id = 20;
    hosts.broccoli.lastBit = 1;
  };
  trusted = {
    id = 30;
    hosts = {
      broccoli.lastBit = 1;
      asparagus = { lastBit = 50; dhcp = true; mac = "e4:1d:2d:7f:1a:d0"; };
      okra = { lastBit = 51; dhcp = true; mac = "5c:80:b6:92:eb:27"; };
    };
  };
  iot = {
    id = 40;
    hosts.broccoli.lastBit = 1;
  };
  work = {
    id = 50;
    hosts.broccoli.lastBit = 1;
  };
  wg-trusted = {
    id = 60;
    hosts = {
      broccoli.lastBit = 1;
      beetroot = { lastBit = 50; wgPeer = true; publicKey = "T+zc4lpoEgxPIKEBr9qXiAzb/ruRbqZuVrih+0rGs2M="; };
    };
  };
  wg-iot = {
    id = 70;
    hosts = {
      broccoli.lastBit = 1;
      pixel = { lastBit = 50; wgPeer = true; publicKey = "pCvnlCWnM46XY3+327rQyOPA91wajC1HPTmP/5YHcy8="; };
    };
  };
}
