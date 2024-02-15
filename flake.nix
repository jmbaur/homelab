{
  description = "NixOS configurations for the homelab";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
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
    neovim.inputs.nixpkgs.follows = "nixpkgs";
    neovim.url = "github:neovim/neovim?dir=contrib";
    nix-sandbox-escape-hatch.inputs.nixpkgs.follows = "nixpkgs";
    nix-sandbox-escape-hatch.url = "github:jmbaur/nix-sandbox-escape-hatch";
    nixos-router.inputs.nixpkgs.follows = "nixpkgs";
    nixos-router.url = "github:jmbaur/nixos-router";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    pre-commit.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit.url = "github:cachix/pre-commit-hooks.nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    tinyboot.inputs.nixpkgs.follows = "nixpkgs";
    tinyboot.url = "github:jmbaur/tinyboot";
    u-boot-nix.inputs.nixpkgs.follows = "nixpkgs";
    u-boot-nix.url = "github:jmbaur/u-boot.nix";
    webauthn-tiny.inputs.nixpkgs.follows = "nixpkgs";
    webauthn-tiny.url = "github:jmbaur/webauthn-tiny";
  };

  outputs = inputs: {
    apps = import ./apps inputs;
    checks = import ./checks.nix inputs;
    devShells = import ./dev-shells.nix inputs;
    formatter = import ./formatter.nix inputs;
    homeConfigurations = import ./home-configurations inputs;
    homeModules = import ./home-modules inputs;
    legacyPackages = import ./legacy-packages.nix inputs;
    nixosConfigurations = import ./nixos-configurations inputs;
    nixosModules = import ./nixos-modules inputs;
    overlays = import ./overlays inputs;
  };
}
