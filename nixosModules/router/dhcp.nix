{ config, lib, ... }:
let
  toKeaArray = data: lib.concatStringsSep "," data;
  dhcpNetworks = lib.filterAttrs (_: network: network.physical.enable) config.custom.inventory.networks;
in
{
  services.kea = {
    dhcp4 = {
      enable = true;
      settings = {
        control-socket = {
          socket-type = "unix";
          socket-name = "/var/run/kea/kea-dhcp4.sock";
        };
        option-def = [{
          name = "classless-static-routes";
          code = 121;
          space = "dhcp4";
          type = "record";
          array = true;
          record-types = "uint8,uint8,uint8,uint8,uint8,uint8,uint8,uint8";
        }];
        reservations-global = false;
        reservations-in-subnet = true;
        reservations-out-of-pool = true;
        interfaces-config = {
          interfaces = lib.mapAttrsToList
            (name: _: config.systemd.network.networks.${name}.name)
            dhcpNetworks;
        };
        subnet4 = lib.flatten (lib.mapAttrsToList
          (_: network:
            with network; [
              {
                interface = config.systemd.network.networks.${name}.name;
                subnet = networkIPv4Cidr;
                pools = [{
                  pool = "${networkIPv4SignificantBits}.100 - ${networkIPv4SignificantBits}.200";
                }];
                option-data = [
                  {
                    name = "routers";
                    data = toKeaArray [ hosts.${config.networking.hostName}.ipv4 ];
                  }
                  {
                    name = "domain-name-servers";
                    data = toKeaArray [ hosts.${config.networking.hostName}.ipv4 ];
                  }
                  {
                    name = "ntp-servers";
                    data = toKeaArray [ hosts.${config.networking.hostName}.ipv4 ];
                  }
                  {
                    name = "domain-search";
                    data = "home.arpa";
                  }
                  {
                    name = "domain-name";
                    data = "home.arpa";
                  }
                ] ++ lib.optional (includeRoutesTo != [ ])
                  (
                    let
                      dotToComma = data: lib.replaceStrings [ "." ] [ "," ] data;
                      router = dotToComma hosts.${config.networking.hostName}.ipv4;
                    in
                    {
                      name = "classless-static-routes";
                      data = toKeaArray (
                        # default route
                        [ "0,${router}" ] ++
                          (map
                            (networkName:
                              let
                                otherNetworkCidr = config.custom.inventory.networks.${networkName}.ipv4Cidr;
                                otherNetwork = dotToComma config.custom.inventory.networks.${networkName}.networkIPv4SignificantBits;
                              in
                              "${toString otherNetworkCidr},${otherNetwork},${router}"
                            )
                            includeRoutesTo)
                      );
                    }
                  ) ++ lib.optional (mtu != null) {
                  name = "interface-mtu";
                  data = network.mtu;
                };
                reservations =
                  lib.mapAttrsToList
                    (_: host: {
                      hw-address = host.mac;
                      ip-address = host.ipv4;
                    })
                    (lib.filterAttrs (_: host: host.dhcp) hosts);
              }
            ]
          )
          dhcpNetworks);
      };
    };
    dhcp6 = {
      enable = true;
      settings = {
        control-socket = {
          socket-type = "unix";
          socket-name = "/var/run/kea/kea-dhcp6.sock";
        };
        reservations-global = false;
        reservations-in-subnet = true;
        reservations-out-of-pool = true;
        interfaces-config = {
          interfaces = lib.mapAttrsToList
            (name: _: config.systemd.network.networks.${name}.name)
            dhcpNetworks;
        };
        subnet6 = lib.flatten (lib.mapAttrsToList
          (_: network:
            with network; [
              {
                interface = config.systemd.network.networks.${name}.name;
                subnet = networkUlaCidr;
                pools = [{
                  pool = "${networkUlaPrefix}:d::/80";
                }];
                reservations =
                  lib.mapAttrsToList
                    (_: host: {
                      hw-address = host.mac;
                      ip-addresses = [ host.ipv6.ula ];
                    })
                    (lib.filterAttrs (_: host: host.dhcp) hosts);
              }
            ]
          )
          dhcpNetworks);
      };
    };
  };
}
