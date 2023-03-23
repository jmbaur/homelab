{ ... }: {
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    sharedModules = [ ./common.nix ./dev.nix ./gui.nix ./laptop.nix ];
  };
}
