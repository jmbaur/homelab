{
  description = "NixOS configurations for the homelab";

  inputs = {
    cn913x_build.flake = false;
    cn913x_build.url = "github:solidrun/cn913x_build";
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    homelab-private.url = "git+ssh://git@github.com/jmbaur/homelab-private";
    ipwatch.url = "github:jmbaur/ipwatch";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
    microvm.url = "github:astro/microvm.nix";
    nixos-configs.url = "github:jmbaur/nixos-configs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    pre-commit.url = "github:cachix/pre-commit-hooks.nix";
    runner-nix.url = "github:jmbaur/runner-nix";
    sops-nix.url = "github:Mic92/sops-nix";
    terranix.url = "github:terranix/terranix";
    webauthn-tiny.url = "github:jmbaur/webauthn-tiny";
  };

  nixConfig = {
    extra-substituters = [
      "https://microvm.cachix.org"
      "https://nix-community.cachix.org"
      "https://jmbaur.cachix.org"
    ];
    extra-trusted-public-keys = [
      "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "jmbaur.cachix.org-1:OpzNp/eBFYOmPtZBjnS6QD0FAPgK4ItMRea0QPuyJYM="
    ];
  };

  outputs = inputs: {
    checks = import ./checks.nix inputs;
    deploy = import ./deploy.nix inputs;
    devShells = import ./devShells.nix inputs;
    formatter = import ./formatter.nix inputs;
    inventory = import ./inventory.nix inputs;
    nixosConfigurations = import ./nixosConfigurations inputs;
    nixosModules = import ./nixosModules inputs;
    overlays = import ./overlays inputs;
    packages = import ./packages inputs;
  };
}
