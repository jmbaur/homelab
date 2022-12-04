{ config, lib, ... }:
let
  mkInternalInterface = network: {
    name = network.physical.interface; # interface name
    linkConfig = {
      ActivationPolicy = "always-up";
    } // lib.optionalAttrs (network.mtu != null) {
      MTUBytes = toString network.mtu;
    };
    networkConfig = {
      Address = [
        "${network.networkIPv4SignificantBits}.1/${toString network.ipv4Cidr}"
        "${network.networkGuaPrefix}::1/${toString network.ipv6Cidr}"
        "${network.networkUlaPrefix}::1/${toString network.ipv6Cidr}"
      ];
      IPv6AcceptRA = false;
      IPv6SendRA = true;
    };
    ipv6SendRAConfig = {
      Managed = true;
      OtherInformation = false;
      DNS = "_link_local";
      Domains = [ "home.arpa" ];
    };
    ipv6Prefixes = map
      (prefix: { ipv6PrefixConfig = { Prefix = prefix; }; })
      (with network; [ networkGuaCidr ]);
    ipv6RoutePrefixes = [{ ipv6RoutePrefixConfig.Route = network.networkUlaCidr; }] ++
      (lib.flatten (map
        (n: [
          { ipv6RoutePrefixConfig.Route = config.custom.inventory.networks.${n}.networkUlaCidr; }
        ])
        network.includeRoutesTo));
  };
in
{
  systemd.network.networks = (
    lib.mapAttrs
      (_: mkInternalInterface)
      (lib.filterAttrs
        (_: network: network.physical.enable)
        config.custom.inventory.networks)
  ) // {
    # TODO(jared): refactor: this is DSA-interface specific configuration.
    lan-master = {
      name = "eth1";
      linkConfig.RequiredForOnline = "no";
      networkConfig = {
        LinkLocalAddressing = "no";
        BindCarrier = map (i: "lan${toString i}") [ 1 2 3 4 5 ];
      };
    };
  };
}
