{
  description = "NixOS configurations for the homelab";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    git-get.url = "github:jmbaur/git-get";
    gobar.url = "github:jmbaur/gobar";
    gosee.url = "github:jmbaur/gosee";
    home-manager.url = "github:nix-community/home-manager";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    promtop.url = "github:jmbaur/promtop";
    sops-nix.url = "github:mic92/sops-nix";
  };

  outputs =
    { self
    , deploy-rs
    , flake-utils
    , git-get
    , gobar
    , gosee
    , home-manager
    , neovim-nightly-overlay
    , nixos-hardware
    , nixpkgs
    , promtop
    , sops-nix
    }@inputs: flake-utils.lib.eachDefaultSystem
      (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ git gnumake terraform ] ++
            [ deploy-rs.defaultPackage.${system} ];
        };
      })
    //
    rec {
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks deploy) deploy-rs.lib;

      overlay = import ./pkgs/overlay.nix;

      nixosModule = import ./modules {
        overlays = [
          git-get.overlay
          gobar.overlay
          gosee.overlay
          neovim-nightly-overlay.overlay
          promtop.overlay
          self.overlay
        ];
      };

      nixosConfigurations.beetroot = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = with inputs.nixos-hardware.nixosModules; [
          ./hosts/beetroot/configuration.nix
          home-manager.nixosModules.home-manager
          lenovo-thinkpad-t480
          nixosModule
        ];
      };

      nixosConfigurations.asparagus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = with nixos-hardware.nixosModules; [
          ./hosts/asparagus/configuration.nix
          home-manager.nixosModules.home-manager
          intel-nuc-8i7beh
          nixosModule
          sops-nix.nixosModules.sops
        ];
      };

      deploy.nodes.asparagus = {
        hostname = "asparagus";
        profiles.system = {
          user = "root";
          sshUser = "deploy";
          path = deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.asparagus;
        };
      };

      nixosConfigurations.kale = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = with nixos-hardware.nixosModules; [
          ./hosts/kale/configuration.nix
          common-cpu-amd
          home-manager.nixosModules.home-manager
          nixosModule
          sops-nix.nixosModule.sops
        ];
      };

      deploy.nodes.kale = {
        hostname = "kale";
        profiles.system = {
          user = "root";
          sshUser = "deploy";
          path = deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.kale;
        };
      };

      nixosConfigurations.rhubarb = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = with nixos-hardware.nixosModules; [
          ./hosts/rhubarb/configuration.nix
          home-manager.nixosModules.home-manager
          nixosModule
          raspberry-pi-4
        ];
      };

      deploy.nodes.rhubarb = {
        hostname = "rhubarb";
        profiles.system = {
          user = "root";
          sshUser = "deploy";
          path = deploy-rs.lib.aarch64-linux.activate.nixos nixosConfigurations.rhubarb;
        };
      };
    };

}
