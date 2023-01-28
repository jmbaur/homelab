{ config, lib, ... }: {
  services.corerad = {
    enable = true;
    settings = {
      debug = { address = ":9430"; prometheus = true; };
      interfaces = lib.mapAttrsToList
        (_: network: {
          name = network.name;
          advertise = true;
          managed = true;
          other_config = false;

          # Advertise all /64 prefixes on the interface.
          prefix = [{ }];

          route =
            let
              routes = (lib.flatten (map
                (n: {
                  prefix = config.custom.inventory.networks.${n}._computed._networkUlaCidr;
                })
                network.includeRoutesTo));
            in
            if routes != [ ] then routes else
              # Automatically propagate routes owned by loopback.
            [{ }];

          # Automatically use the appropriate interface address as a DNS server.
          rdnss = [{ }];

          dnssl = [{ domain_names = [ network.domain "home.arpa" ]; }];
        })
        (lib.filterAttrs
          (_: network: network.physical.enable)
          config.custom.inventory.networks);
    };
  };
}
