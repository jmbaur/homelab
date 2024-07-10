{
  description = "NixOS configurations for the homelab";

  inputs = {
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.url = "github:cachix/git-hooks.nix";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    ipwatch.inputs.nixpkgs.follows = "nixpkgs";
    ipwatch.url = "github:jmbaur/ipwatch";
    nixos-router.inputs.nixpkgs.follows = "nixpkgs";
    nixos-router.url = "github:jmbaur/nixos-router";
    nixpkgs.url = "github:jmbaur/nixpkgs/homelab";
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
