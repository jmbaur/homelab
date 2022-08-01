{ pkgs, lib, inventory, ... }:
let
  domain = "home.arpa";
  mkInternalInterface = network: {
    name = network.hosts.artichoke.interface;
    linkConfig = {
      ActivationPolicy = "always-up";
    } // lib.optionalAttrs (network.mtu != null) {
      MTUBytes = toString network.mtu;
    };
    networkConfig = {
      Address = [
        "${network.hosts.artichoke.ipv4}/${toString network.ipv4Cidr}"
        "${network.hosts.artichoke.ipv6.gua}/${toString network.ipv6Cidr}"
        "${network.hosts.artichoke.ipv6.ula}/${toString network.ipv6Cidr}"
      ];
      IPv6AcceptRA = false;
      DHCPServer = true;
      IPv6SendRA = true;
    };
    ipv6SendRAConfig = {
      Managed = network.managed;
      OtherInformation = false;
      DNS = "_link_local";
      Domains = [ domain ];
    };
    ipv6Prefixes = map
      (prefix: { ipv6PrefixConfig = { Prefix = prefix; }; })
      (with network; [ networkGuaCidr ]);
    # TODO(jared): Use dedicated option field when this is merged:
    # https://github.com/NixOS/nixpkgs/pull/184340
    # TODO(jared): Should we advertise the ULA network via RA or via DHCPv6?
    extraConfig = (lib.optionalString network.managed ''
      [IPv6RoutePrefix]
      Route=${network.networkUlaCidr}
    '') + (lib.concatMapStrings
    (n:
    let
      mainNetwork = network;
      linkedNetwork = inventory.networks.${n};
    in ''
      [IPv6RoutePrefix]
      Route=${linkedNetwork.networkGuaCidr}
    '' + (lib.optionalString mainNetwork.managed ''
      [IPv6RoutePrefix]
      Route=${linkedNetwork.networkUlaCidr}
    ''))
    network.includeRoutesTo);
    dhcpServerConfig = {
      PoolOffset = 50;
      PoolSize = 200;
      EmitDNS = "yes";
      DNS = "_server_address";
      EmitNTP = "yes";
      NTP = "_server_address";
      SendOption = [
        "15:string:${domain}"
      ] ++ lib.optional (network.includeRoutesTo != [ ]) (
        let
          # NOTE: This function spits out data for RFC3442's classless static routes
          # in a format that systemd-networkd's DHCP server can consume.
          formatRFC3442 = bits: builtins.readFile (pkgs.runCommandNoCC "format-rfc3442" { } ''
            printf "\\\\x%.2X" ${toString bits} | tee $out
          '');
          gatewayRFC3442 = formatRFC3442 (lib.splitString "." network.hosts.artichoke.ipv4);
          defaultRouteRFC3442 = "\\x00" + gatewayRFC3442;
          otherRoutesRFC3442 = map
            (n:
              with inventory.networks.${n};
              (formatRFC3442
                ([ (toString ipv4Cidr) ] ++ (lib.splitString "." networkIPv4SignificantBits))
              ) + gatewayRFC3442
            )
            network.includeRoutesTo;
          data = defaultRouteRFC3442 + (lib.concatStrings otherRoutesRFC3442);
        in
        "121:string:${data}"
      )
      ++ lib.optional (network.mtu != null) "26:uint16:${toString network.mtu}";
    };
    dhcpServerStaticLeases = lib.flatten
      (lib.mapAttrsToList
        (_: host: {
          dhcpServerStaticLeaseConfig = {
            MACAddress = host.mac;
            Address = host.ipv4;
          };
        })
        (lib.filterAttrs (_: host: host.dhcp) network.hosts));
  };
  public = mkInternalInterface inventory.networks.public;
  trusted = mkInternalInterface inventory.networks.trusted;
  iot = mkInternalInterface inventory.networks.iot;
  work = mkInternalInterface inventory.networks.work;
  mgmt = mkInternalInterface inventory.networks.mgmt;
  data = mkInternalInterface inventory.networks.data;
in
{
  systemd.network.networks = {
    lan-master = {
      name = "eth1";
      linkConfig.RequiredForOnline = "no";
      networkConfig = {
        LinkLocalAddressing = "no";
        BindCarrier = map (i: "lan${toString i}") [ 1 2 3 4 5 ];
      };
    };
    inherit mgmt
      public
      trusted
      iot
      work
      # data
      ;
  };
}
