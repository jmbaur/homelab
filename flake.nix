{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs, nixpkgs-unstable }: {
    nixosConfigurations.beetroot = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/beetroot/configuration.nix
        ({ ... }: {
          nixpkgs.overlays = [
            (final: prev: {
              unstable = nixpkgs-unstable.legacyPackages.${prev.system}; # considering nixpkgs-unstable is an input registered before.
            })
          ];
        })
      ];
    };
  };
}
