{ config, ... }:
let
  mkCoreradInterface = { managed ? false, other_config ? false }: ifi: {
    inherit (ifi) name;
    verbose = true;
    advertise = true;
    inherit managed other_config;
    prefix = [{ }]; # automatically do the correct thing
    rdnss = [{ }]; # automatically do the correct thing
    dnssl = [{ domain_names = [ "home.arpa" ]; }];
  };
  mkManagedCoreradInterface = mkCoreradInterface { managed = true; };
  mkUnmanagedCoreradInterface = mkCoreradInterface { managed = false; };
in
{
  services.corerad = {
    enable = true;
    settings = {
      # interfaces = with config.networking.interfaces;
      #   (builtins.map mkUnmanagedCoreradInterface [ trusted iot guest ]) ++
      #   (builtins.map mkManagedCoreradInterface [ mgmt ]);
      debug = { address = ":9430"; prometheus = true; };
    };
  };
}
