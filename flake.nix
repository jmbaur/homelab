{
  description = "NixOS configurations for the homelab";

  inputs = {
    nixpkgs.url = "github:jmbaur/nixpkgs/jmbaur-nixos-unstable";

    git-hooks.url = "github:cachix/git-hooks.nix";
    home-manager.url = "github:nix-community/home-manager";
    ipwatch.url = "github:jmbaur/ipwatch";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nixos-router.url = "github:jmbaur/nixos-router";
    sops-nix.url = "github:Mic92/sops-nix";
    tinyboot.url = "github:jmbaur/tinyboot";
    u-boot-nix.url = "github:jmbaur/u-boot.nix";
    webauthn-tiny.url = "github:jmbaur/webauthn-tiny";

    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    ipwatch.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nixos-router.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    tinyboot.inputs.nixpkgs.follows = "nixpkgs";
    u-boot-nix.inputs.nixpkgs.follows = "nixpkgs";
    webauthn-tiny.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {
    apps = import ./apps inputs;
    checks = import ./checks inputs;
    devShells = import ./dev-shells.nix inputs;
    formatter = import ./formatter.nix inputs;
    homeConfigurations = import ./home-configurations inputs;
    hydraJobs = import ./hydra-jobs inputs;
    legacyPackages = import ./legacy-packages.nix inputs;
    nixosConfigurations = import ./nixos-configurations inputs;
    nixosModules = import ./nixos-modules inputs;
    overlays = import ./overlays inputs;
    packages = import ./packages inputs;
  };
}
