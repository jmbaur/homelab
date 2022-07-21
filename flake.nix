{
  description = "NixOS configurations for the homelab";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    ipwatch.url = "github:jmbaur/ipwatch";
    pre-commit.url = "github:cachix/pre-commit-hooks.nix";
    agenix.url = "github:ryantm/agenix";
    terranix.url = "github:terranix/terranix";
    blog.url = "github:jmbaur/blog";
    nixos-configs = {
      url = "github:jmbaur/nixos-configs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homelab-private = {
      url = "git+ssh://git@github.com/jmbaur/homelab-private";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cn913x_build = {
      url = "github:solidrun/cn913x_build";
      flake = false;
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://microvm.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
  };

  outputs = { self, ... }@inputs: {
    checks = import ./checks.nix { inherit self inputs; };
    deploy = import ./deploy.nix { inherit self inputs; };
    devShells = import ./devShells.nix { inherit self inputs; };
    inventory = import ./inventory.nix { inherit self inputs; };
    nixosConfigurations = import ./nixosConfigurations.nix { inherit self inputs; };
    nixosModules = import ./nixosModules.nix { inherit self inputs; };
    packages = import ./packages.nix { inherit self inputs; };
  };
}
