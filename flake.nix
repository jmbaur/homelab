{
  description = "NixOS configurations for the homelab";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    git-get.url = "github:jmbaur/git-get";
    gobar.url = "github:jmbaur/gobar";
    gosee.url = "github:jmbaur/gosee";
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    hosts.url = "github:StevenBlack/hosts";
    neovim.url = "github:jmbaur/neovim";
    nixos-hardware = { url = "github:NixOS/nixos-hardware"; inputs.nixpkgs.follows = "nixpkgs"; };
    nixpkgs.url = "nixpkgs/nixos-unstable";
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
    , neovim
    , nixos-hardware
    , nixpkgs
    , sops-nix
    }@inputs: flake-utils.lib.eachDefaultSystem
      (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      { devShell = pkgs.mkShell { buildInputs = [ pkgs.sops ]; }; })
    //
    {
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      overlay = import ./pkgs/overlay.nix;

      nixosModule = {
        imports = [
          ./modules
          home-manager.nixosModules.home-manager
          hosts.nixosModule
          sops-nix.nixosModules.sops
        ];
        nixpkgs.overlays = [
          deploy-rs.overlay
          git-get.overlay
          gobar.overlay
          gosee.overlay
          neovim.overlay
          self.overlay
        ];
      };

      nixosConfigurations.broccoli = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/broccoli/configuration.nix
          nixos-hardware.nixosModules.supermicro
          self.nixosModule
        ];
      };

      deploy.nodes.broccoli = {
        hostname = "broccoli";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.broccoli;
        };
      };

      nixosConfigurations.beetroot = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/beetroot/configuration.nix
          nixos-hardware.nixosModules.lenovo-thinkpad-t495
          self.nixosModule
        ];
      };

      nixosConfigurations.asparagus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/asparagus/configuration.nix
          nixos-hardware.nixosModules.common-cpu-amd
          nixos-hardware.nixosModules.common-pc
          self.nixosModule
        ];
      };

      deploy.nodes.asparagus = {
        hostname = "asparagus";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.asparagus;
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

      nixosConfigurations.kale = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/kale/configuration.nix
          nixos-hardware.nixosModules.common-cpu-amd
          self.nixosModule
          ({
            containers.www.path = self.nixosConfigurations.www.config.system.build.toplevel;
            containers.media.path = self.nixosConfigurations.media.config.system.build.toplevel;
          })
        ];
      };

      deploy.nodes.kale = {
        hostname = "kale";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.kale;
        };
      };

      nixosConfigurations.rhubarb = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hosts/rhubarb/configuration.nix
          nixos-hardware.nixosModules.raspberry-pi-4
          self.nixosModule
        ];
      };

      deploy.nodes.rhubarb = {
        hostname = "localhost";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.rhubarb;
        };
      };
    };

}
