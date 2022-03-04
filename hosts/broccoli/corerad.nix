{ config, ... }: {
  services.corerad = {
    enable = true;
    settings = {
      interfaces = builtins.map
        (ifi: with config.networking.interfaces.${ifi}; {
          inherit name;
          verbose = true;
          advertise = true;
          prefix = [{ }]; # automatically do the correct thing
          rdnss = [{ }]; # automatically do the correct thing
          dnssl = [{ domain_names = [ "home.arpa" ]; }];
        }) [ "trusted" "iot" "guest" "mgmt" ];
      debug = { address = ":9430"; prometheus = true; };
    };
  };
}
