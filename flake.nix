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
    disko.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    gobar.inputs.nixpkgs.follows = "nixpkgs";
    gobar.url = "github:jmbaur/gobar";
    gosee.inputs.nixpkgs.follows = "nixpkgs";
    gosee.url = "github:jmbaur/gosee";
    ipwatch.inputs.nixpkgs.follows = "nixpkgs";
    ipwatch.url = "github:jmbaur/ipwatch";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote/v0.3.0";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
    microvm.url = "github:astro/microvm.nix";
    neovim.inputs.nixpkgs.follows = "nixpkgs";
    neovim.url = "github:neovim/neovim?dir=contrib";
    nix-sandbox-escape-hatch.inputs.nixpkgs.follows = "nixpkgs";
    nix-sandbox-escape-hatch.url = "github:jmbaur/nix-sandbox-escape-hatch";
    nixos-router.inputs.nixpkgs.follows = "nixpkgs";
    nixos-router.url = "github:jmbaur/nixos-router";
    nixpkgs.url = "github:jmbaur/nixpkgs/nixos-unstable";
    pd-notify.inputs.nixpkgs.follows = "nixpkgs";
    pd-notify.url = "github:jmbaur/pd-notify";
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
    legacyPackages = import ./legacy-packages.nix inputs;
    nixosConfigurations = import ./nixos-configurations inputs;
    nixosModules = import ./nixos-modules inputs;
    overlays = import ./overlays inputs;
  };
}
