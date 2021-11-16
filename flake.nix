{
  description = "NixOS configuration";
  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };
  outputs = { self, nixpkgs, nixpkgs-unstable }: {
    nixosConfigurations.beetroot = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/beetroot/configuration.nix ];
    };
  };
}
