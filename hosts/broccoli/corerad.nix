{ config, ... }:
let
  # https://github.com/mdlayher/corerad/blob/main/internal/config/reference.toml
  mkCoreradInterface = { managed ? false, other_config ? false }: name: {
    inherit name managed other_config;
    verbose = true;
    advertise = true;
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
    enable = false;
    settings = {
      interfaces =
        (builtins.map mkUnmanagedCoreradInterface (builtins.map getInterfaceName [ "trusted" "iot" "guest" ])) ++
        (builtins.map mkManagedCoreradInterface (builtins.map getInterfaceName [ "mgmt" ]));
      debug = { address = ":9430"; prometheus = true; };
    };
  };
}
