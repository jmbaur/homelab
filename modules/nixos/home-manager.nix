{ config, ... }: {
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { systemConfig = config; };
    sharedModules = [
      ../home-manager
      ({
        custom = { inherit (config.custom) common dev gui laptop; };
      })
    ];
  };
}
