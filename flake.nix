{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-21.05";
  };
  outputs = { self, nixpkgs, nixpkgs-stable }: {
    nixosConfigurations.beetroot = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/beetroot/configuration.nix ];
    };
    nixopsConfigurations.default = {
      nixpkgs = nixpkgs-stable;
      network = {
        description = "homelab";
        enableRollback = true;
        storage.legacy.databasefile = "~/.nixops/deployments.nixops";
      };
      broccoli = { config, pkgs, ... }: {
        deployment.targetHost = "broccoli.home.arpa.";
        imports = [ ./lib/nixops.nix ./hosts/broccoli/configuration.nix ];
      };
      rhubarb = { config, pkgs, ... }: {
        deployment.targetHost = "rhubarb.home.arpa.";
        imports = [ ./lib/nixops.nix ./hosts/rhubarb/configuration.nix ];
      };
      asparagus = { config, pkgs, ... }: {
        deployment.targetHost = "asparagus.home.arpa.";
        imports = [ ./lib/nixops.nix ./hosts/asparagus/configuration.nix ];
      };
    };
  };
}
