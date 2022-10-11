{ config, lib, inventory, ... }: {
  services.kea = {
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
