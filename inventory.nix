{ lib }:
# NOTE: None of this uses math to calculate network CIDR masks and such, so it
# is all assumed to have clean CIDR masks such as /24 for ipv4 and /64 for
# ipv6.
# NOTE: The parameters of this function, guaPrefix and ulaPrefix, are of the
# form X:X:X where X is an IPv6 hextet. Each prefix is a /48 network prefix to
# prepend to the remaining 80 bits of an IPv6 address.
{ guaPrefix
, ulaPrefix
, tld
}:
let
  mkIpv4Addr = prefix: thirdOctet: fourthOctet: "${prefix}.${toString thirdOctet}.${toString fourthOctet}";
  mkIpv6Addr = prefix: fourthHextet: lastHextet: "${prefix}.${fourthHextet}::${lastHextet}";
  mkHost = { dhcp ? false, lastBit }: {
    ipv4 = [ ];
    inherit dhcp;
  };
in
{
  mgmt =
    let
      ipv4ThirdOctet = 88;
      mkMgmtIpv4Addr = mkIpv4Addr "192.168" ipv4ThirdOctet;
      mkMgmtGuaIpv6Addr = mkIpv6Addr guaPrefix (lib.toHexString ipv4ThirdOctet);
      mkMgmtUlaIpv6Addr = mkIpv6Addr ulaPrefix (lib.toHexString ipv4ThirdOctet);
    in
    {
      domain = "mgmt.${tld}";
      hosts = {
        broccoli = let lastBit = 1; in
          {
            ipv4 = [ (mkMgmtIpv4Addr lastBit) ];
            ipv6 = [ (mkMgmtGuaIpv6Addr (lib.toHexString lastBit)) (mkMgmtUlaIpv6Addr (lib.toHexString lastBit)) ];
            dhcp = false;
          };
        switch0 = let lastBit = 2; in
          {
            ipv4 = [ (mkMgmtIpv4Addr lastBit) ];
            ipv6 = [ (mkMgmtGuaIpv6Addr (lib.toHexString lastBit)) (mkMgmtUlaIpv6Addr (lib.toHexString lastBit)) ];
            dhcp = false;
          };
        switch1 = let lastBit = 3; in
          {
            ipv4 = [ (mkMgmtIpv4Addr lastBit) ];
            ipv6 = [ (mkMgmtGuaIpv6Addr (lib.toHexString lastBit)) (mkMgmtUlaIpv6Addr (lib.toHexString lastBit)) ];
            dhcp = false;
          };
        ap0 = let lastBit = 4; in
          {
            ipv4 = [ (mkMgmtIpv4Addr lastBit) ];
            ipv6 = [ (mkMgmtGuaIpv6Addr (lib.toHexString lastBit)) (mkMgmtUlaIpv6Addr (lib.toHexString lastBit)) ];
            dhcp = false;
          };
        kale = let lastBit = 52; in
          {
            ipv4 = [ (mkMgmtIpv4Addr lastBit) ];
            ipv6 = [ (mkMgmtGuaIpv6Addr (lib.toHexString lastBit)) (mkMgmtUlaIpv6Addr (lib.toHexString lastBit)) ];
            dhcp = true;
          };
        asparagus = let lastBit = 54; in
          {
            ipv4 = [ (mkMgmtIpv4Addr lastBit) ];
            ipv6 = [ (mkMgmtGuaIpv6Addr (lib.toHexString lastBit)) (mkMgmtUlaIpv6Addr (lib.toHexString lastBit)) ];
            dhcp = true;
          };
      };
    };
  pubwan = { };
  publan = { };
  trusted =
    let
      ipv4ThirdOctet = 30;
      mkTrustedIpv4Addr = mkIpv4Addr "192.168" ipv4ThirdOctet;
      mkTrustedGuaIpv6Addr = mkIpv6Addr guaPrefix (lib.toHexString ipv4ThirdOctet);
      mkTrustedUlaIpv6Addr = mkIpv6Addr ulaPrefix (lib.toHexString ipv4ThirdOctet);
    in
    {
      domain = "trusted.${tld}";
      hosts = {
        asparagus = let lastBit = 50; in
          {
            ipv4 = [ (mkTrustedIpv4Addr lastBit) ];
            ipv6 = [ (mkTrustedGuaIpv6Addr (lib.toHexString lastBit)) (mkTrustedUlaIpv6Addr (lib.toHexString lastBit)) ];
            dhcp = true;
          };
        okra = let lastBit = 51; in
          {
            ipv4 = [ (mkTrustedIpv4Addr lastBit) ];
            ipv6 = [ (mkTrustedGuaIpv6Addr (lib.toHexString lastBit)) (mkTrustedUlaIpv6Addr (lib.toHexString lastBit)) ];
            dhcp = true;
          };
      };
    };
  guest = { };
  work = { };
}
