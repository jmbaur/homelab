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
  getInterfaceName = attr: config.systemd.network.networks.${attr}.matchConfig.Name;
in
{
  services.corerad = {
    enable = true;
    settings = {
      interfaces =
        (builtins.map mkUnmanagedCoreradInterface (builtins.map getInterfaceName [ "trusted" "iot" "guest" ])) ++
        (builtins.map mkManagedCoreradInterface (builtins.map getInterfaceName [ "mgmt" ]));
      debug = { address = ":9430"; prometheus = true; };
    };
  };
}
