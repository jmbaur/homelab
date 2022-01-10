{
  description = "NixOS configurations for the homelab";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    git-get.url = "github:jmbaur/git-get";
    gosee.url = "github:jmbaur/gosee";
    neovim.url = "github:neovim/neovim?dir=contrib";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "nixpkgs/nixos-21.11-small";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    promtop.url = "github:jmbaur/promtop";
    zig.url = "github:arqv/zig-overlay";
  };

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem
    (system:
      let pkgs = inputs.nixpkgs.legacyPackages.${system}; in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ git gnumake nixopsUnstable terraform ansible ] ++
            pkgs.lib.singleton inputs.deploy-rs.defaultPackage.${system};
          # inherit (checks.pre-commit-check) shellHook;
        };
        packages.p = pkgs.callPackage ./pkgs/p.nix { };
      })
  //
  inputs.flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system: rec {
    packages.installer = inputs.nixpkgs.legacyPackages.${system}.callPackage ./installer.nix { };
    packages.iso = (import "${inputs.nixpkgs}/nixos" {
      inherit system; configuration = { config, pkgs, ... }: {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
      ];
      environment.etc."nixos/bootstrap-configuration.nix".source = ./bootstrap-configuration.nix;
      environment.shellInit = "${packages.installer}/bin/install";
      services.qemuGuest.enable = true;
    };
    }).config.system.build.isoImage;
  })
  //
  rec {
    # recommended by deploy-rs
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks deploy) inputs.deploy-rs.lib;
    # checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
    #   src = builtins.path { path = ./.; };
    #   hooks.nixpkgs-fmt.enable = true;
    # };


    nixosConfigurations.asparagus = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = with inputs.nixos-hardware.nixosModules; [
        common-pc-ssd
        common-cpu-intel
        ./lib/common.nix
        ./lib/deploy.nix
        ./hosts/asparagus/configuration.nix
      ];
    };

    deploy.nodes.asparagus = {
      hostname = "asparagus.home.arpa.";
      profiles.system = {
        user = "root";
        sshUser = "deploy";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.asparagus;
      };
    };

    nixosConfigurations.rhubarb = inputs.nixpkgs.lib.nixosSystem rec {
      system = "aarch64-linux";
      modules = with inputs.nixos-hardware.nixosModules; [
        ({ ... }: {
          nixpkgs.overlays = [ inputs.promtop.overlay.${system} ];
          nixpkgs.localSystem = {
            inherit system;
            config = "aarch64-unknown-linux-gnu";
          };
        })
        raspberry-pi-4
        ./lib/common.nix
        ./lib/deploy.nix
        ./hosts/rhubarb/configuration.nix
      ];
    };

    deploy.nodes.rhubarb = {
      hostname = "rhubarb.home.arpa.";
      profiles.system = {
        user = "root";
        sshUser = "deploy";
        path = inputs.deploy-rs.lib.aarch64-linux.activate.nixos nixosConfigurations.rhubarb;
      };
    };

    nixosConfigurations.dev = inputs.nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        ({ ... }: {
          nixpkgs.overlays = [
            inputs.neovim.overlay
            inputs.git-get.overlay.${system}
            inputs.gosee.overlay.${system}
            (import ./pkgs/zig.nix)
            (import ./pkgs/zls.nix)
            (import ./pkgs/nix-direnv.nix)
            (self: super: { p = super.callPackage ./pkgs/p.nix { }; })
          ];
        })
        ./hosts/dev/configuration.nix
        ./config
      ];
    };

    nixosConfigurations.kodi = inputs.nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        ./hosts/kodi/configuration.nix
        ./lib/deploy.nix
      ];
    };

    deploy.nodes.kodi = {
      hostname = "kodi.home.arpa.";
      profiles.system = {
        user = "root";
        sshUser = "deploy";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.kodi;
      };
    };

    nixosConfigurations.deploy = inputs.nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        ./hosts/deploy/configuration.nix
        ./lib/deploy.nix
      ];
    };

    deploy.nodes.deploy = {
      hostname = "deploy.home.arpa.";
      profiles.system = {
        user = "root";
        sshUser = "deploy";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.deploy;
      };
    };

    nixopsConfigurations.default = {
      nixpkgs = inputs.nixpkgs;
      network = { description = "homelab"; storage.memory = { }; };
      broccoli = { ... }: {
        deployment = {
          targetHost = "broccoli.home.arpa.";
          targetUser = "deploy";
        };
        imports = with inputs.nixos-hardware.nixosModules; [
          common-pc-ssd
          common-cpu-intel
          ./lib/common.nix
          ./lib/deploy.nix
          ./lib/supermicro.nix
          ./hosts/broccoli/configuration.nix
        ];
      };
    };
  };

}
