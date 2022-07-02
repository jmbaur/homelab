{
  description = "NixOS configurations for the homelab";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    ipwatch.url = "github:jmbaur/ipwatch";
    pre-commit.url = "github:cachix/pre-commit-hooks.nix";
    agenix.url = "github:ryantm/agenix";
    terranix.url = "github:terranix/terranix";
    blog.url = "github:jmbaur/blog";
    nixos-configs = {
      url = "github:jmbaur/nixos-configs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homelab-private = {
      url = "git+ssh://git@github.com/jmbaur/homelab-private";
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

  nixConfig.extra-substituters = [ "https://microvm.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys=" ];

  outputs =
    { self
    , deploy-rs
    , flake-utils
    , home-manager
    , homelab-private
    , nixos-configs
    , ipwatch
    , microvm
    , nixos-hardware
    , nixpkgs
    , pre-commit
    , agenix
    , terranix
    , blog
    , ...
    }@inputs:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ]
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ deploy-rs.overlay agenix.overlay ];
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          buildInputs = [
            (pkgs.terraform.withPlugins (p: [ p.cloudflare ]))
            pkgs.agenix
            pkgs.deploy-rs.deploy-rs
          ];
          inherit (pre-commit.lib.${system}.run {
            src = builtins.path { path = ./.; };
            hooks.nixpkgs-fmt.enable = true;
          }) shellHook;
        };
        packages.iso = (nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            # Provide an initial copy of the NixOS channel so that the user
            # doesn't need to run "nix-channel --update" first.
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
            ./iso.nix
          ];
        }).config.system.build.isoImage;
        packages.crs_305 = pkgs.callPackage ./routeros/crs305/configuration.nix {
          inventoryFile = self.packages.${system}.inventory;
        };
        packages.crs_326 = pkgs.callPackage ./routeros/crs326/configuration.nix {
          inventoryFile = self.packages.${system}.inventory;
        };
        packages.cap_ac = pkgs.callPackage ./routeros/capac/secretsWrapper.nix {
          inventoryFile = self.packages.${system}.inventory;
          configurationFile = ./routeros/capac/configuration.nix;
        };
        packages.cloud = terranix.lib.terranixConfiguration {
          inherit pkgs system;
          extraArgs = {
            inherit (self.inventory.${system}) inventory;
            secrets = homelab-private.secrets;
          };
          modules = [ ./cloud ];
        };
        packages.inventory = pkgs.writeText
          "inventory.json"
          (builtins.toJSON (self.inventory.${system}.inventory));
        inventory = pkgs.callPackage ./inventory.nix {
          inherit (homelab-private.secrets.networking) guaPrefix;
          ulaPrefix = "fd82:f21d:118d";
          tld = "jmbaur.com";
          inherit (pkgs) lib;
        };
      })
    //
    {
      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy)
        deploy-rs.lib;

      nixosConfigurations.broccoli = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          inherit (homelab-private) secrets;
          inherit (self.inventory.${system}) inventory;
        };
        modules = [
          ./hosts/broccoli/configuration.nix
          agenix.nixosModules.age
          homelab-private.nixosModules.common
          ipwatch.nixosModules.default
          nixos-configs.nixosModules.default
          nixos-hardware.nixosModules.supermicro
          { nixpkgs.overlays = [ ipwatch.overlays.default ]; }
        ];
      };

      deploy.nodes.broccoli = {
        hostname = "broccoli.mgmt.home.arpa";
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
          homelab-private.nixosModules.common
          nixos-configs.nixosModules.default
          nixos-hardware.nixosModules.lenovo-thinkpad-t495
        ];
      };

      nixosConfigurations.okra = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/okra/configuration.nix
          homelab-private.nixosModules.common
          nixos-configs.nixosModules.default
          nixos-hardware.nixosModules.intel-nuc-8i7beh
        ];
      };

      deploy.nodes.okra = {
        hostname = "okra.trusted.home.arpa";
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
          homelab-private.nixosModules.common
          nixos-configs.nixosModules.default
          nixos-hardware.nixosModules.common-cpu-amd
          nixos-hardware.nixosModules.common-gpu-amd
        ];
      };

      deploy.nodes.asparagus = {
        hostname = "asparagus.mgmt.home.arpa";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.asparagus;
        };
      };

      nixosConfigurations.website = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; inherit (self.inventory.${system}) inventory; };
        modules = [
          ./vms/website.nix
          microvm.nixosModules.microvm
        ];
      };

      nixosConfigurations.kale = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = { inherit (self.inventory.${system}) inventory; };
        modules = [
          ./hosts/kale/configuration.nix
          agenix.nixosModules.age
          homelab-private.nixosModules.common
          microvm.nixosModules.host
          nixos-configs.nixosModules.default
          nixos-hardware.nixosModules.common-cpu-amd
          { microvm.vms = { website.flake = self; }; }
        ];
      };

      deploy.nodes.kale = {
        hostname = "kale.mgmt.home.arpa";
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
          homelab-private.nixosModules.common
          nixos-hardware.nixosModules.raspberry-pi-4
        ];
      };

      deploy.nodes.rhubarb = {
        hostname = "rhubarb.mgmt.home.arpa";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.aarch64-linux.activate.nixos
            self.nixosConfigurations.rhubarb;
        };
      };
    };
}
