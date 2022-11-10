{ config, ... }: {
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { systemConfig = config; };
    sharedModules = [
      ../home-manager
      ({ config, ... }: {
        custom = { inherit (config.custom) common dev gui laptop; };
      })
    ];
  };
}
