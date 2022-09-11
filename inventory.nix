# NOTE: None of this uses math to calculate network CIDR masks and such, so it
# is all assumed to have clean CIDR masks such as /24 for ipv4 and /64 for
# ipv6.

# NOTE: The parameters of this function, guaPrefix and ulaPrefix, are of the
# form X:X:X where X is an IPv6 hextet. Each prefix is a /48 network prefix to
# prepend to the remaining 80 bits of an IPv6 address.

inputs: with inputs;
flake-utils.lib.eachDefaultSystemMap
  (system:
    let
      pkgs = import nixpkgs { inherit system; };
      inherit (homelab-private.secrets.networking) guaPrefix;
      ulaPrefix = "fd82:f21d:118d";
      v4Prefix = "172.16";
      tld = "jmbaur.com";
      inherit (pkgs) lib;

      # NOTE: Wrapping nixpkgs toHexString to follow RFC 5952's recommendation for
      # IPv6 addresses to be in lower case.
      toIpHexString = i: lib.toLower (lib.toHexString i);
      mkIPv4Addr = prefix: thirdOctet: fourthOctet: "${prefix}.${toString thirdOctet}.${toString fourthOctet}";
      mkIPv6Addr = prefix: fourthHextet: lastHextet: "${prefix}:${fourthHextet}::${lastHextet}";
      mkHost = networkId: name: { dhcp ? false
                                , interface ? null
                                , mac ? null
                                , wgPeer ? false
                                , publicKey ? null
                                , lastBit
                                }:
        let
        in
        {
          inherit name interface dhcp mac wgPeer publicKey;
          ipv4 = mkIPv4Addr v4Prefix networkId lastBit;
          ipv6 = {
            gua = (mkIPv6Addr guaPrefix (toIpHexString networkId) (toIpHexString lastBit));
            ula = (mkIPv6Addr ulaPrefix (toIpHexString networkId) (toIpHexString lastBit));
          };
        };
      mkNetwork = name: { id, mtu ? null, hosts, wireguard ? false, includeRoutesTo ? [ ] }:
        let
          mkNetworkHost = mkHost id;
          ipv4Cidr = 24;
          ipv6Cidr = 64;
          networkIPv4SignificantBits = "${v4Prefix}.${toString id}";
          networkIPv4 = mkIPv4Addr v4Prefix id 0;
          networkIPv4Cidr = "${networkIPv4}/${toString ipv4Cidr}";
          networkGuaPrefix = "${guaPrefix}:${toIpHexString id}";
          networkUlaPrefix = "${ulaPrefix}:${toIpHexString id}";
          networkGuaCidr = "${networkGuaPrefix}::/${toString ipv6Cidr}";
          networkUlaCidr = "${networkUlaPrefix}::/${toString ipv6Cidr}";
          networkHosts = lib.mapAttrs (name: hostInfo: mkNetworkHost name hostInfo) hosts;
        in
        {
          inherit
            id
            ipv4Cidr
            ipv6Cidr
            mtu
            name
            networkGuaCidr
            networkGuaPrefix
            networkIPv4
            networkIPv4Cidr
            networkIPv4SignificantBits
            networkUlaCidr
            networkUlaPrefix
            includeRoutesTo
            wireguard;
          domain = "${name}.home.arpa";
          hosts = networkHosts;
          managed = wireguard || ((lib.filterAttrs (_: host: host.dhcp) networkHosts) != { });
        };
    in
    {
      inventory = {
        inherit tld guaPrefix ulaPrefix;
        networks = lib.mapAttrs (name: networkInfo: mkNetwork name networkInfo) {
          mgmt = {
            id = 10;
            hosts = {
              artichoke = { lastBit = 1; interface = "lan1"; };
              switch0.lastBit = 2;
              switch1.lastBit = 3;
              # ap0.lastBit = 4; # TODO
              potato-ipmi = { lastBit = 51; dhcp = true; mac = "d0:50:99:f7:c4:8d"; };
              potato = { lastBit = 52; dhcp = true; mac = "d0:50:99:fe:1e:e2"; };
              kale = { lastBit = 62; dhcp = true; mac = "d0:63:b4:03:db:66"; };
              rhubarb = { lastBit = 53; dhcp = true; mac = "dc:a6:32:20:50:f2"; };
              asparagus = { lastBit = 54; dhcp = true; mac = "e4:1d:2d:7f:1a:d0"; };
            };
          };
          public = {
            id = 20;
            hosts = {
              artichoke = { lastBit = 1; interface = "lan2"; };
              website.lastBit = 11;
            };
          };
          trusted = {
            id = 30;
            includeRoutesTo = [ "wg-trusted" ];
            hosts = {
              artichoke = { lastBit = 1; interface = "lan3"; };
              asparagus = { lastBit = 50; dhcp = true; mac = "e4:1d:2d:7f:1a:d0"; };
              okra = { lastBit = 51; dhcp = true; mac = "5c:80:b6:92:eb:27"; };
            };
          };
          wg-trusted = {
            id = 31;
            wireguard = true;
            includeRoutesTo = [ "mgmt" "trusted" ];
            hosts = {
              artichoke = { lastBit = 1; interface = "wg-trusted"; };
              beetroot = { lastBit = 52; wgPeer = true; publicKey = "T+zc4lpoEgxPIKEBr9qXiAzb/ruRbqZuVrih+0rGs2M="; };
              carrot = { lastBit = 51; wgPeer = true; publicKey = "XcKlp41XBEtrplIcXkxwQQUyT2kyJ/X4QcmckCnNU3w="; };
            };
          };
          iot = {
            id = 40;
            includeRoutesTo = [ "wg-iot" ];
            hosts = {
              artichoke = { lastBit = 1; interface = "lan4"; };
            };
          };
          wg-iot = {
            id = 41;
            wireguard = true;
            includeRoutesTo = [ "iot" ];
            hosts = {
              artichoke = { lastBit = 1; interface = "wg-iot"; };
              phone = { lastBit = 50; wgPeer = true; publicKey = "pCvnlCWnM46XY3+327rQyOPA91wajC1HPTmP/5YHcy8="; };
            };
          };
          work = {
            id = 50;
            includeRoutesTo = [ "wg-work" ];
            hosts = {
              artichoke = { lastBit = 1; interface = "lan5"; };
              laptop = { lastBit = 50; dhcp = true; mac = "08:3a:88:63:1a:b4"; };
              dev = { lastBit = 60; dhcp = true; mac = "00:0C:29:88:A7:13"; };
            };
          };
          wg-work = {
            id = 51;
            wireguard = true;
            hosts = {
              artichoke = { lastBit = 1; interface = "wg-work"; };
              okra = { lastBit = 2; wgPeer = true; publicKey = "XG/mq6Gdghxu6iW68tdlArnjJei8VCYk9cUl/i81LDA="; };
            };
          };
          data = {
            id = 60;
            mtu = 9000;
            hosts = { artichoke = { lastBit = 1; interface = "data"; }; };
          };
        };
      };
    })
