{
  description = "NixOS configurations for the homelab";

  inputs = {
    cn913x_build.flake = false;
    cn913x_build.url = "github:solidrun/cn913x_build";
    deploy-rs.url = "github:serokell/deploy-rs";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
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
    nixos-router.inputs.nixpkgs.follows = "nixpkgs";
    nixos-router.url = "github:jmbaur/nixos-router";
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
    tinyboot.inputs.nixpkgs.follows = "nixpkgs";
    tinyboot.url = "github:jmbaur/tinyboot";
    webauthn-tiny.inputs.nixpkgs.follows = "nixpkgs";
    webauthn-tiny.url = "github:jmbaur/webauthn-tiny";

    # TODO(jared): delete if/when merged
    nixpkgs-extlinux-specialisation.url = "github:jmbaur/nixpkgs/extlinux-specialisation";
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
    nixosConfigurations = import ./nixos-configurations inputs;
    nixosModules = import ./nixos-modules inputs;
    overlays = import ./overlays inputs;
    packages = import ./packages inputs;
    apps = import ./apps inputs;
  };
}
