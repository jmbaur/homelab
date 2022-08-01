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
    nixos-configs.url = "github:jmbaur/nixos-configs";
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
    extra-substituters = [ "https://microvm.cachix.org" ];
    extra-trusted-public-keys = [ "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys=" ];
  };

  outputs = inputs: {
    checks = import ./checks.nix inputs;
    deploy = import ./deploy.nix inputs;
    devShells = import ./devShells.nix inputs;
    formatter = import ./formatter.nix inputs;
    inventory = import ./inventory.nix inputs;
    nixosConfigurations = import ./nixosConfigurations.nix inputs;
    nixosModules = import ./nixosModules inputs;
    overlays = import ./overlays inputs;
    packages = import ./packages inputs;
  };
}
