{
  description = "NixOS configurations for the homelab";

  inputs = {
    auto-follow.url = "github:fzakaria/nix-auto-follow";
    git-hooks.url = "github:cachix/git-hooks.nix";
    home-manager.url = "github:nix-community/home-manager";
    ipwatch.url = "github:jmbaur/ipwatch";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixos-router.url = "github:jmbaur/nixos-router";
    nixpkgs.url = "github:jmbaur/nixpkgs/jmbaur-nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    tinyboot.url = "github:jmbaur/tinyboot";
    u-boot-nix.url = "github:jmbaur/u-boot.nix";
    webauthn-tiny.url = "github:jmbaur/webauthn-tiny";

    auto-follow.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    ipwatch.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";
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
    homeModules = import ./home-modules inputs;
    hydraJobs = import ./hydra-jobs inputs;
    legacyPackages = import ./legacy-packages.nix inputs;
    nixosConfigurations = import ./nixos-configurations inputs;
    nixosModules = import ./nixos-modules inputs;
    overlays = import ./overlays inputs;
  };
}
