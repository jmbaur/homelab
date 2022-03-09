{
  description = "NixOS configurations for the homelab";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    git-get.url = "github:jmbaur/git-get";
    gobar.url = "github:jmbaur/gobar";
    gosee.url = "github:jmbaur/gosee";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hosts.url = "github:StevenBlack/hosts";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/nur";
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
    , hosts
    , neovim-nightly-overlay
    , nixos-hardware
    , nixpkgs
    , nur
    , promtop
    , sops-nix
    }@inputs: flake-utils.lib.eachDefaultSystem
      (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ qrencode git gnumake sops terraform ] ++
            [ deploy-rs.defaultPackage.${system} ];
        };
      })
    //
    rec {
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks deploy) deploy-rs.lib;

      overlay = import ./pkgs/overlay.nix;

      nixosModule = { ... }: {
        imports = [
          ./modules
          home-manager.nixosModules.home-manager
          hosts.nixosModule
          sops-nix.nixosModules.sops
        ];
        nixpkgs.overlays = [
          git-get.overlay
          gobar.overlay
          gosee.overlay
          neovim-nightly-overlay.overlay
          nur.overlay
          promtop.overlay
          self.overlay
        ];
      };

      homeConfigurations.jared = let username = "jared"; in
        home-manager.lib.homeManagerConfiguration {
          configuration = import ./homes/jared;
          extraModules = [
            ({
              nixpkgs.overlays = [
                git-get.overlay
                gobar.overlay
                gosee.overlay
                neovim-nightly-overlay.overlay
                nur.overlay
                promtop.overlay
                self.overlay
              ];
            })
          ];
          homeDirectory = "/home/${username}";
          stateVersion = "21.11";
          system = "x86_64-linux";
          inherit username;
        };

      nixosConfigurations.broccoli = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/broccoli/configuration.nix
          nixosModule
        ];
      };

      deploy.nodes.broccoli = {
        hostname = "broccoli";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.broccoli;
        };
      };

      nixosConfigurations.beetroot = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/beetroot/configuration.nix
          nixos-hardware.nixosModules.lenovo-thinkpad-t480
          nixosModule
        ];
      };

      nixosConfigurations.asparagus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/asparagus/configuration.nix
          nixos-hardware.nixosModules.intel-nuc-8i7beh
          nixosModule
        ];
      };

      deploy.nodes.asparagus = {
        hostname = "fd82:f21d:118d:1e:1e69:7aff:fe64:45b2";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.asparagus;
        };
      };

      nixosConfigurations.www = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./containers/www sops-nix.nixosModules.sops ];
      };

      nixosConfigurations.media = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./containers/media sops-nix.nixosModules.sops ];
      };

      nixosConfigurations.dev = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./containers/dev nixosModule ];
      };

      nixosConfigurations.kale = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/kale/configuration.nix
          nixos-hardware.nixosModules.common-cpu-amd
          nixosModule
          ({
            containers.www.path = nixosConfigurations.www.config.system.build.toplevel;
            containers.media.path = nixosConfigurations.media.config.system.build.toplevel;
            containers.dev.path = nixosConfigurations.dev.config.system.build.toplevel;
          })
        ];
      };

      deploy.nodes.kale = {
        hostname = "kale";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.kale;
        };
      };

      nixosConfigurations.rhubarb = nixpkgs.lib.nixosSystem
        {
          system = "aarch64-linux";
          modules = [
            ./hosts/rhubarb/configuration.nix
            nixos-hardware.nixosModules.raspberry-pi-4
            nixosModule
          ];
        };

      deploy.nodes.rhubarb = {
        hostname = "rhubarb";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.aarch64-linux.activate.nixos nixosConfigurations.rhubarb;
        };
      };
    };

}
