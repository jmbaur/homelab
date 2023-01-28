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
          prefix = [{ prefix = "::/64"; }];
          route = (lib.flatten (map
            (n: {
              prefix = config.custom.inventory.networks.${n}._computed._networkUlaCidr;
            })
            network.includeRoutesTo));
          rdnss = [{ servers = [ "::" ]; }];
          dnssl = [{ domain_names = [ network.domain "home.arpa" ]; }];
        })
        (lib.filterAttrs
          (_: network: network.physical.enable)
          config.custom.inventory.networks);
    };
  };
}
