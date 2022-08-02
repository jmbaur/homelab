{
  description = "NixOS configurations for the homelab";

  inputs = {
    agenix.url = "github:ryantm/agenix";
    blog.url = "github:jmbaur/blog";
    cn913x_build.flake = false;
    cn913x_build.url = "github:solidrun/cn913x_build";
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    homelab-private.url = "git+ssh://git@github.com/jmbaur/homelab-private";
    ipwatch.url = "github:jmbaur/ipwatch";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
    microvm.url = "github:astro/microvm.nix";
    nixos-configs.url = "github:jmbaur/nixos-configs";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    pre-commit.url = "github:cachix/pre-commit-hooks.nix";
    terranix.url = "github:terranix/terranix";
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
