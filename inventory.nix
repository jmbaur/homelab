{ lib }:
# NOTE: None of this uses math to calculate network CIDR masks and such, so it
# is all assumed to have clean CIDR masks such as /24 for ipv4 and /64 for
# ipv6.
# NOTE: The parameters of this function, guaPrefix and ulaPrefix, are of the
# form X:X:X where X is an IPv6 hextet. Each prefix is a /48 network prefix to
# prepend to the remaining 80 bits of an IPv6 address.

let
  # Forked from nixpkgs lib to use lowercase in hex representation, per RFC
  # 5952's recommendation for IPv6 addresses.
  toHexString = i:
    let
      toHexDigit = d:
        if d < 10
        then toString d
        else
          {
            "10" = "a";
            "11" = "b";
            "12" = "c";
            "13" = "d";
            "14" = "e";
            "15" = "f";
          }.${toString d};
    in
    lib.concatMapStrings toHexDigit (lib.toBaseDigits 16 i);
  mkIpv4Addr = prefix: thirdOctet: fourthOctet: "${prefix}.${toString thirdOctet}.${toString fourthOctet}";
  mkIpv6Addr = prefix: fourthHextet: lastHextet: "${prefix}:${fourthHextet}::${lastHextet}";
in

{ guaPrefix
, ulaPrefix
, tld
}:
let
  mkHost = networkId: { dhcp ? false, lastBit }: {
    inherit dhcp;
    ipv4 = [ (mkIpv4Addr "192.168" networkId lastBit) ];
    ipv6 = [
      (mkIpv6Addr guaPrefix (toHexString networkId) (toHexString lastBit))
      (mkIpv6Addr ulaPrefix (toHexString networkId) (toHexString lastBit))
    ];
  };
in
{
  mgmt = let mkMgmtHost = mkHost 88; in
    {
      domain = "mgmt.${tld}";
      hosts = {
        broccoli = mkMgmtHost { lastBit = 1; dhcp = false; };
        switch0 = mkMgmtHost { lastBit = 2; dhcp = false; };
        switch1 = mkMgmtHost { lastBit = 3; dhcp = false; };
        ap0 = mkMgmtHost { lastBit = 4; dhcp = false; };
        kale = mkMgmtHost { lastBit = 52; dhcp = true; };
        asparagus = mkMgmtHost { lastBit = 54; dhcp = true; };
      };
    };
  pubwan = let mkPubwanHost = mkHost 10; in
    {
      hosts.broccoli = mkPubwanHost { lastBit = 1; dhcp = false; };
    };
  publan = let mkPublanHost = mkHost 20; in
    {
      hosts.broccoli = mkPublanHost { lastBit = 1; dhcp = false; };
    };
  trusted = let mkTrustedHost = mkHost 30; in
    {
      domain = "trusted.${tld}";
      hosts = {
        broccoli = mkTrustedHost { lastBit = 1; dhcp = false; };
        asparagus = mkTrustedHost { lastBit = 50; dhcp = true; };
        okra = mkTrustedHost { lastBit = 51; dhcp = true; };
      };
    };
  iot = let mkIotHost = mkHost 40; in
    {
      hosts.broccoli = mkIotHost { lastBit = 1; dhcp = false; };
    };
  work = let mkWorkHost = mkHost 50; in
    {
      hosts.broccoli = mkWorkHost { lastBit = 1; dhcp = false; };
    };
}
