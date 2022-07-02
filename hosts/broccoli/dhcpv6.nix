{ config, lib, inventory, ... }: {
  services.kea = {
    dhcp6 = {
      enable = true;
      extraArgs = [ "-d" ];
      settings = {
        interfaces-config = {
          interfaces = map
            (name: config.systemd.network.networks.${name}.name)
            [ "pubwan" "publan" "trusted" "iot" "work" "mgmt" ];
        };
        subnet6 = lib.flatten (map
          (name:
            [
              {
                interface = config.systemd.network.networks.${name}.name;
                subnet = inventory.networks.${name}.networkUlaCidr;
                pools = [
                  {
                    pool =
                      "${inventory.networks.${name}.networkUlaPrefix}::00ff"
                      + "-" +
                      "${inventory.networks.${name}.networkUlaPrefix}::ff00";
                  }
                ];
                reservations =
                  lib.mapAttrsToList
                    (_: host: {
                      hw-address = host.mac;
                      ip-addresses = [ host.ipv6.ula ];
                    })
                    (lib.filterAttrs (_: host: host.dhcp) inventory.networks.${name}.hosts);
              }
            ]
          )
          [ "pubwan" "publan" "trusted" "iot" "work" "mgmt" ]);
      };
    };
  };
}
