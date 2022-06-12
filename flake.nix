{
  description = "NixOS configurations for the homelab";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    ipwatch.url = "github:jmbaur/ipwatch";
    pre-commit.url = "github:cachix/pre-commit-hooks.nix";
    sops-nix.url = "github:mic92/sops-nix";
    terranix.url = "github:terranix/terranix";
    hosts = {
      url = "github:StevenBlack/hosts";
      flake = false;
    };
    nixos-configs = {
      url = "github:jmbaur/nixos-configs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homelab-private = {
      url = "github:jmbaur/homelab-private";
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
    , home-manager
    , homelab-private
    , nixos-configs
    , ipwatch
    , microvm
    , nixos-hardware
    , nixpkgs
    , pre-commit
    , sops-nix
    , terranix
    , ...
    }@inputs:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ]
      (system:
      let
        pkgs = import nixpkgs { inherit system; };
        nix2rascal = pkgs.callPackage ./routeros/nix2rascal.nix { };
        nix2rascalWithData = nix2rascal {
          inventoryFile = self.packages.${system}.inventory;
          secretsFile = ./routeros/secrets.yaml;
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            (terraform.withPlugins (p: with p; [ aws cloudflare github ]))
            sops
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
        packages.crs_305 = nix2rascalWithData ./routeros/crs305/configuration.nix;
        packages.crs_326 = nix2rascalWithData ./routeros/crs326/configuration.nix;
        packages.cap_ac = nix2rascalWithData ./routeros/capac/configuration.nix;
        packages.cloud = terranix.lib.terranixConfiguration {
          inherit system;
          modules = [ ./config.nix ];
        };
        packages.inventory = pkgs.writeText "inventory.json"
          (builtins.toJSON self.inventory.${system});
        inventory = (pkgs.callPackage ./inventory.nix { }) {
          inherit (homelab-private.secrets.networking) guaPrefix ulaPrefix;
          tld = "jmbaur.com";
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
          inventory = self.inventory.${system};
        };
        modules = [
          ./hosts/broccoli/configuration.nix
          homelab-private.nixosModules.broccoli
          homelab-private.nixosModules.common
          ipwatch.nixosModules.default
          nixos-configs.nixosModules.default
          nixos-hardware.nixosModules.supermicro
          sops-nix.nixosModules.sops
          { nixpkgs.overlays = [ ipwatch.overlays.default ]; }
        ];
      };

      deploy.nodes.broccoli = {
        hostname = "broccoli.mgmt.jmbaur.com";
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
          sops-nix.nixosModules.sops
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
        hostname = "okra.trusted.jmbaur.com";
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
          sops-nix.nixosModules.sops
          nixos-hardware.nixosModules.common-cpu-amd
          nixos-hardware.nixosModules.common-gpu-amd
        ];
      };

      deploy.nodes.asparagus = {
        hostname = "asparagus.mgmt.jmbaur.com";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.asparagus;
        };
      };

      nixosConfigurations.vm-test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./vms/test.nix
          homelab-private.nixosModules.common
          microvm.nixosModules.microvm
        ];
      };

      nixosConfigurations.kale = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/kale/configuration.nix
          homelab-private.nixosModules.common
          microvm.nixosModules.host
          nixos-hardware.nixosModules.common-cpu-amd
          ({ microvm.vms.vm-test.flake = self; })
        ];
      };

      deploy.nodes.kale = {
        hostname = "kale.mgmt.jmbaur.com";
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
        hostname = "rhubarb.mgmt.jmbaur.com";
        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.aarch64-linux.activate.nixos
            self.nixosConfigurations.rhubarb;
        };
      };
    };

}
