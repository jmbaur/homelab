{ config, lib, inventory, ... }:
let
  toKeaArray = data: lib.concatStringsSep "," data;
in
{
  services.kea = {
    dhcp4 = {
      enable = true;
      settings = {
        control-socket = {
          socket-type = "unix";
          socket-name = "/run/kea/kea-dhcp4.socket";
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
          interfaces = map
            (name: config.systemd.network.networks.${name}.name)
            [ "trusted" "iot" "work" "mgmt" ];
        };
        subnet4 = lib.flatten (map
          (name:
            with inventory.networks.${name}; [
              {
                interface = config.systemd.network.networks.${name}.name;
                subnet = networkIPv4Cidr;
                pools = [{
                  pool = "${networkIPv4SignificantBits}.100 - ${networkIPv4SignificantBits}.200";
                }];
                option-data = [
                  {
                    name = "domain-name-servers";
                    data = toKeaArray [ hosts.${config.networking.hostName}.ipv4 ];
                  }
                  {
                    name = "ntp-servers";
                    data = toKeaArray [ hosts.${config.networking.hostName}.ipv4 ];
                  }
                  {
                    name = "domain-name";
                    data = "home.arpa";
                  }
                ] ++ lib.optional (includeRoutesTo != [ ]) {
                  name = "classless-static-routes";
                  data = toKeaArray (map
                    (networkName:
                      let
                        dotToComma = data: lib.replaceStrings [ "." ] [ "," ] data;
                        router = dotToComma hosts.${config.networking.hostName}.ipv4;
                        otherNetworkCidr = inventory.networks.${networkName}.ipv4Cidr;
                        otherNetwork = dotToComma inventory.networks.${networkName}.networkIPv4SignificantBits;
                      in
                      "${toString otherNetworkCidr},${otherNetwork},${router}"
                    )
                    includeRoutesTo);
                } ++ lib.optional (mtu != null) {
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
          [ "trusted" "iot" "work" "mgmt" ]);
      };
    };
    dhcp6 = {
      enable = true;
      settings = {
        control-socket = {
          socket-type = "unix";
          socket-name = "/run/kea/kea-dhcp6.socket";
        };
        reservations-global = false;
        reservations-in-subnet = true;
        reservations-out-of-pool = true;
        interfaces-config = {
          interfaces = map
            (name: config.systemd.network.networks.${name}.name)
            [ "trusted" "iot" "work" "mgmt" ];
        };
        subnet6 = lib.flatten (map
          (name:
            with inventory.networks.${name}; [
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
          [ "trusted" "iot" "work" "mgmt" ]);
      };
    };
  };
}
