{ config, lib, ... }: {
  services.corerad = {
    enable = true;
    settings = {
      debug = { address = ":9430"; prometheus = true; };
      interfaces = lib.mapAttrsToList
        (name: network: {
          name = config.systemd.network.networks.${name}.name;
          advertise = true;
          managed = true;
          other_config = false;
          dnssl = [{ domain_names = [ network.domain "home.arpa" ]; }];

          # Advertise all /64 prefixes on the interface.
          prefix = [{ }];

          # Automatically use the appropriate interface address as a DNS server.
          rdnss = [{ }];
        } // (
          let
            route = (lib.flatten (map
              (n: {
                prefix = config.custom.inventory.networks.${n}._computed._networkUlaCidr;
              })
              network.includeRoutesTo));
          in
          lib.optionalAttrs (route != [ ]) { inherit route; }
        ))
        (lib.filterAttrs
          (_: network: network.physical.enable)
          config.custom.inventory.networks);
    };
  };
}
