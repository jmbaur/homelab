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
      toHexString = i: lib.toLower (lib.toHexString i);
      mkIPv4Addr = prefix: thirdOctet: fourthOctet: "${prefix}.${toString thirdOctet}.${toString fourthOctet}";
      mkIPv6Addr = prefix: fourthHextet: lastHextet: "${prefix}:${fourthHextet}::${lastHextet}";
      mkHost = networkId: name: { dhcp ? false
                                , interface ? null
                                , mac ? null
                                , wgPeer ? false
                                , publicKey ? null
                                , lastBit
                                }: {
        inherit name interface dhcp mac wgPeer publicKey;
        ipv4 = mkIPv4Addr v4Prefix networkId lastBit;
        ipv6 = {
          gua = (mkIPv6Addr guaPrefix (toHexString networkId) (toHexString lastBit));
          ula = (mkIPv6Addr ulaPrefix (toHexString networkId) (toHexString lastBit));
        };
      };
      mkNetwork = name: { id, mtu ? null, wireguard ? false, hosts }:
        let
          mkNetworkHost = mkHost id;
          ipv4Cidr = 24;
          ipv6Cidr = 64;
          networkIPv4 = mkIPv4Addr v4Prefix id 0;
          networkIPv4Cidr = "${networkIPv4}/${toString ipv4Cidr}";
          networkGuaPrefix = "${guaPrefix}:${toHexString id}";
          networkUlaPrefix = "${ulaPrefix}:${toHexString id}";
          networkGuaCidr = "${networkGuaPrefix}::/${toString ipv6Cidr}";
          networkUlaCidr = "${networkUlaPrefix}::/${toString ipv6Cidr}";
          wgHost = lib.optionalAttrs wireguard (mkHost id "wg-${name}" {
            interface = "wg-${name}";
            lastBit = 2;
          })
          ;
          networkHosts = lib.mapAttrs
            (name: hostInfo: mkNetworkHost name hostInfo)
            (hosts // wgHost);
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
            networkUlaCidr
            networkUlaPrefix
            wireguard;
          domain = "${name}.home.arpa";
          hosts = networkHosts;
          managed = (lib.filterAttrs (_: host: host.dhcp) networkHosts) != { };
        };
    in
    {
      inventory = {
        inherit tld;
        networks = lib.mapAttrs (name: networkInfo: mkNetwork name networkInfo) {
          mgmt = {
            id = 10;
            hosts = {
              artichoke = { lastBit = 1; interface = "lan1"; };
              switch0 = { lastBit = 2; dhcp = true; mac = "18:FD:74:32:D7:B7"; };
              # switch1 = { lastBit = 3; dhcp = true; mac = "TODO"; };
              # ap0 = { lastBit = 4; dhcp = true; mac = "TODO"; };
              kale-ipmi = { lastBit = 51; dhcp = true; mac = "d0:50:99:f7:c4:8d"; };
              kale = { lastBit = 52; dhcp = true; mac = "d0:50:99:fe:1e:e2"; };
              kale2 = { lastBit = 62; dhcp = true; mac = "d0:63:b4:03:db:66"; };
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
            wireguard = true;
            hosts = {
              artichoke = { lastBit = 1; interface = "lan3"; };
              asparagus = { lastBit = 50; dhcp = true; mac = "e4:1d:2d:7f:1a:d0"; };
              okra = { lastBit = 51; dhcp = true; mac = "5c:80:b6:92:eb:27"; };
              beetroot = { lastBit = 52; wgPeer = true; publicKey = "T+zc4lpoEgxPIKEBr9qXiAzb/ruRbqZuVrih+0rGs2M="; };
            };
          };
          iot = {
            id = 40;
            wireguard = true;
            hosts = {
              artichoke = { lastBit = 1; interface = "lan4"; };
              pixel = { lastBit = 50; wgPeer = true; publicKey = "pCvnlCWnM46XY3+327rQyOPA91wajC1HPTmP/5YHcy8="; };
            };
          };
          work = {
            id = 50;
            wireguard = true;
            hosts = {
              artichoke = { lastBit = 1; interface = "lan5"; };
              laptop = { lastBit = 50; dhcp = true; mac = "08:3a:88:63:1a:b4"; };
            };
          };
          data = {
            id = 60;
            mtu = 9000;
            hosts = {
              artichoke = { lastBit = 1; interface = "data"; };
              # kale2 = { lastBit = 2; dhcp = true; mac = "TODO"; };
              # kale = { lastBit = 3; dhcp = true; mac = "TODO"; };
            };
          };
        };
      };
    })
