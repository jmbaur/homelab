{
  description = "NixOS configurations for the homelab";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    git-get.url = "github:jmbaur/git-get";
    gosee.url = "github:jmbaur/gosee";
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
        # checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        #   src = builtins.path { path = ./.; };
        #   hooks.nixpkgs-fmt.enable = true;
        # };
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ git gnumake nixopsUnstable ] ++
            pkgs.lib.singleton inputs.deploy-rs.defaultPackage.${system};
          # inherit (checks.pre-commit-check) shellHook;
        };
        packages.p = pkgs.callPackage ./pkgs/p.nix { };
      }) // rec {

    # recommended by deploy-rs
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks deploy) inputs.deploy-rs.lib;

    nixosConfigurations.asparagus = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = with inputs.nixos-hardware.nixosModules; [
        common-pc-ssd
        common-cpu-intel
        ./lib/nixops.nix
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

    nixosConfigurations.rhubarb =
      let system = "aarch64-linux"; in
      inputs.nixpkgs.lib.nixosSystem {
        modules = with inputs.nixos-hardware.nixosModules;[
          ({ ... }: {
            nixpkgs.overlays = [ inputs.promtop.overlay.${system} ];
            nixpkgs.localSystem = {
              inherit system;
              config = "aarch64-unknown-linux-gnu";
            };
          })
          raspberry-pi-4
          ./lib/nixops.nix
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

    nixosConfigurations.spinach = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = with inputs.nixos-hardware.nixosModules; [
        # common-pc-ssd # TODO(jared): enable this?
        common-cpu-intel
        ./lib/nixops.nix
        ./lib/supermicro.nix
        ./hosts/spinach/configuration.nix
      ];
    };

    deploy.nodes.spinach = {
      hostname = "spinach.home.arpa.";
      profiles.system = {
        user = "root";
        sshUser = "deploy";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos nixosConfigurations.spinach;
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
        nix.trustedUsers = [ "deploy" ];
        imports = with inputs.nixos-hardware.nixosModules; [
          common-pc-ssd
          common-cpu-intel
          ./lib/nixops.nix
          ./lib/supermicro.nix
          ./hosts/broccoli/configuration.nix
        ];
      };
    };
  };
}
