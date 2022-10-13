{ pkgs, lib, inventory, ... }:
let
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
      IPv6SendRA = true;
    };
    ipv6SendRAConfig = {
      Managed = network.managed;
      OtherInformation = false;
      DNS = "_link_local";
      Domains = [ "home.arpa" ];
    };
    ipv6Prefixes = map
      (prefix: { ipv6PrefixConfig = { Prefix = prefix; }; })
      (with network; [ networkGuaCidr ]);
    # TODO(jared): Should we advertise the ULA network via RA or via DHCPv6?
    ipv6RoutePrefixes = (lib.optional network.managed {
      ipv6RoutePrefixConfig = {
        Route = network.networkUlaCidr;
      };
    }) ++ (lib.flatten (map
      (n:
        let
          remoteNetwork = inventory.networks.${n};
        in
        ([
          ({
            ipv6RoutePrefixConfig = {
              Route = remoteNetwork.networkGuaCidr;
            };
          })
        ] ++ (lib.optional remoteNetwork.managed {
          ipv6RoutePrefixConfig = {
            Route = remoteNetwork.networkUlaCidr;
          };
        })
        ))
      network.includeRoutesTo));
  };
  trusted = mkInternalInterface inventory.networks.trusted;
  iot = mkInternalInterface inventory.networks.iot;
  work = mkInternalInterface inventory.networks.work;
  mgmt = mkInternalInterface inventory.networks.mgmt;
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
      trusted
      iot
      work
      # data
      ;
  };
}
