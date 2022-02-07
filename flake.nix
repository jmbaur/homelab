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
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixpkgs.url = "nixpkgs/nixos-21.11";
    promtop.url = "github:jmbaur/promtop";
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
    , nixpkgs-unstable
    , promtop
    }@inputs: flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ git gnumake terraform ] ++
            [ deploy-rs.defaultPackage.${system} ];
        };
      })
    // rec {
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks deploy) deploy-rs.lib;

      nixosConfigurations.beetroot = nixpkgs-unstable.lib.nixosSystem {
        system = "x86_64-linux";
        modules = with inputs.nixos-hardware.nixosModules; [
          ({
            nixpkgs.overlays = (import ./pkgs/overlays.nix) ++ [
              git-get.overlay
              gobar.overlay
              gosee.overlay
              neovim-nightly-overlay.overlay
              promtop.overlay
            ];
          })
          home-manager.nixosModules.home-manager
          lenovo-thinkpad-t480
          ./modules
          ./hosts/beetroot/configuration.nix
        ];
      };

      nixosConfigurations.asparagus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = with nixos-hardware.nixosModules; [
          intel-nuc-8i7beh
          ./modules
          ./hosts/asparagus/configuration.nix
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
          common-cpu-amd
          ./modules
          ./hosts/kale/configuration.nix
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
          raspberry-pi-4
          ./modules
          ./hosts/rhubarb/configuration.nix
        ];
      };

      deploy.nodes.rhubarb = {
        hostname = "192.168.20.192";
        profiles.system = {
          user = "root";
          sshUser = "deploy";
          path = deploy-rs.lib.aarch64-linux.activate.nixos nixosConfigurations.rhubarb;
        };
      };
    };

}
