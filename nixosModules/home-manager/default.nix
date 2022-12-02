{ config, ... }: {
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { systemConfig = config; };
    sharedModules = [ ./common.nix ./dev.nix ./gui.nix ./laptop.nix ];
  };
}
