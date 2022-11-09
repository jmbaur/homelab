{
  description = "NixOS configurations for the homelab";

  inputs = {
    cn913x_build.flake = false;
    cn913x_build.url = "github:solidrun/cn913x_build";
    deploy-rs.url = "github:serokell/deploy-rs";
    git-get.inputs.nixpkgs.follows = "nixpkgs";
    git-get.url = "github:jmbaur/git-get";
    gobar.inputs.nixpkgs.follows = "nixpkgs";
    gobar.url = "github:jmbaur/gobar";
    gosee.inputs.nixpkgs.follows = "nixpkgs";
    gosee.url = "github:jmbaur/gosee";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    ipwatch.inputs.nixpkgs.follows = "nixpkgs";
    ipwatch.url = "github:jmbaur/ipwatch";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
    microvm.url = "github:astro/microvm.nix";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    pd-notify.inputs.nixpkgs.follows = "nixpkgs";
    pd-notify.url = "github:jmbaur/pd-notify";
    pre-commit.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit.url = "github:cachix/pre-commit-hooks.nix";
    runner-nix.inputs.nixpkgs.follows = "nixpkgs";
    runner-nix.url = "github:jmbaur/runner-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    terranix.url = "github:terranix/terranix";
    webauthn-tiny.inputs.nixpkgs.follows = "nixpkgs";
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
    apps = import ./apps inputs;
    checks = import ./checks.nix inputs;
    deploy = import ./deploy.nix inputs;
    devShells = import ./devShells.nix inputs;
    formatter = import ./formatter.nix inputs;
    nixosConfigurations = import ./nixosConfigurations inputs;
    nixosModules = import ./modules/nixos inputs;
    overlays = import ./overlays inputs;
    packages = import ./packages inputs;
  };
}
