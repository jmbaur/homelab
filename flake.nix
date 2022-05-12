{
  description = "NixOS configurations for the homelab";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    git-get.url = "github:jmbaur/git-get";
    gobar.url = "github:jmbaur/gobar";
    gosee.url = "github:jmbaur/gosee";
    ipwatch.url = "github:jmbaur/ipwatch";
    nixpkgs-jmbaur.url = "github:jmbaur/nixpkgs/mosh-378dfa6";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    pre-commit.url = "github:cachix/pre-commit-hooks.nix";
    sops-nix.url = "github:mic92/sops-nix";
    wallpapers.url = "github:jmbaur/procedural-wallpapers";
    hosts = {
      url = "github:StevenBlack/hosts";
      flake = false;
    };
    homelab-private = {
      url = "github:jmbaur/homelab-private";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = "github:jmbaur/neovim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , deploy-rs
    , flake-utils
    , git-get
    , gobar
    , gosee
    , home-manager
    , homelab-private
    , ipwatch
    , microvm
    , neovim
    , nixos-hardware
    , nixpkgs
    , nixpkgs-jmbaur
    , pre-commit
    , sops-nix
    , wallpapers
    , ...
    }@inputs: flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.sops ];
          inherit (pre-commit.lib.${system}.run {
            src = builtins.path { path = ./.; };
            hooks.nixpkgs-fmt.enable = true;
          }) shellHook;

        };
      })
    //
    {
      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy)
        deploy-rs.lib;

      overlays.default = import ./pkgs/overlay.nix;

      nixosModules.default = {
        imports = [
          ./modules
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
        ];
        nixpkgs.overlays = [
          deploy-rs.overlay
          git-get.overlays.default
          gobar.overlay
          gosee.overlays.default
          ipwatch.overlays.default
          neovim.overlays.default
          wallpapers.overlays.default
          self.overlays.default
          (final: prev: {
            inherit (nixpkgs-jmbaur.legacyPackages.${prev.system}) mosh;
          })
        ];
      };

      nixosConfigurations.broccoli = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/broccoli/configuration.nix
          homelab-private.nixosModules.broccoli
          ipwatch.nixosModules.default
          nixos-hardware.nixosModules.supermicro
          self.nixosModules.default
        ];
      };

      deploy.nodes.broccoli = {
        hostname = "broccoli.home.arpa";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.broccoli;
        };
      };

      nixosConfigurations.beetroot = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/beetroot/configuration.nix
          homelab-private.nixosModules.beetroot
          nixos-hardware.nixosModules.lenovo-thinkpad-t495
          self.nixosModules.default
        ];
      };

      nixosConfigurations.okra = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/okra/configuration.nix
          homelab-private.nixosModules.okra
          nixos-hardware.nixosModules.intel-nuc-8i7beh
          self.nixosModules.default
        ];
      };

      deploy.nodes.okra = {
        hostname = "okra.home.arpa";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.okra;
        };
      };

      nixosConfigurations.asparagus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/asparagus/configuration.nix
          homelab-private.nixosModules.asparagus
          nixos-hardware.nixosModules.common-cpu-amd
          nixos-hardware.nixosModules.common-gpu-amd
          self.nixosModules.default
        ];
      };

      deploy.nodes.asparagus = {
        hostname = "asparagus.home.arpa";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.asparagus;
        };
      };

      nixosConfigurations.test-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./vms/test-vm.nix
          microvm.nixosModules.microvm
        ];
      };

      nixosConfigurations.kale = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/kale/configuration.nix
          homelab-private.nixosModules.kale
          microvm.nixosModules.host
          nixos-hardware.nixosModules.common-cpu-amd
          self.nixosModules.default
          # ({ microvm.vms.test-vm.flake = self; })
        ];
      };

      deploy.nodes.kale = {
        hostname = "kale.home.arpa";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.kale;
        };
      };

      nixosConfigurations.rhubarb = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/rhubarb/configuration.nix
          homelab-private.nixosModules.rhubarb
          nixos-hardware.nixosModules.raspberry-pi-4
          self.nixosModules.default
        ];
      };

      deploy.nodes.rhubarb = {
        hostname = "rhubarb.home.arpa";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.aarch64-linux.activate.nixos
            self.nixosConfigurations.rhubarb;
        };
      };
    };

}
