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
        "${network._computed._networkIPv4SignificantBits}.1/${toString network._computed._ipv4Cidr}"
        "${network._computed._networkGuaSignificantBits}::1/${toString network._computed._ipv6GuaCidr}"
        "${network._computed._networkUlaSignificantBits}::1/${toString network._computed._ipv6UlaCidr}"
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
      (with network; [ _computed._networkGuaCidr ]);
    ipv6RoutePrefixes = [{
      ipv6RoutePrefixConfig.Route = network._computed._networkUlaCidr;
    }] ++ (lib.flatten (map
      (n: [{
        ipv6RoutePrefixConfig.Route = config.custom.inventory.networks.${n}._computed._networkUlaCidr;
      }])
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
