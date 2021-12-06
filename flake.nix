{
  description = "NixOS configurations for homelab";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    git-get.url = "github:jmbaur/git-get";
    gosee.url = "github:jmbaur/gosee";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs-stable-small.url = "nixpkgs/nixos-21.11-small";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    zig.url = "github:arqv/zig-overlay?rev=080ef681b4ab24f96096ca5d7672d5336006fa65";
  };

  outputs = inputs: inputs.flake-utils.lib.eachSystem inputs.flake-utils.lib.allSystems
    (system:
      let pkgs = inputs.nixpkgs.legacyPackages.${system}; in
      rec {
        checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = builtins.path { path = ./.; };
          hooks.nixpkgs-fmt.enable = true;
        };
        devShell = pkgs.mkShell {
          buildInputs = with pkgs;[ git gnumake ];
          inherit (checks.pre-commit-check) shellHook;
        };
      }) // inputs.flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] (system: {
    packages.nixosConfigurations.beetroot = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = with inputs.nixos-hardware.nixosModules; [
        common-pc-ssd
        common-cpu-amd
        common-gpu-amd
        common-pc-laptop-acpi_call
        lenovo-thinkpad
        (import ./pkgs/overlays.nix {
          extraOverlays = [
            (self: super: {
              gosee = inputs.gosee.defaultPackage.${system};
              git-get = inputs.git-get.defaultPackage.${system};
            })
          ];
        })
        ./config
        ./lib/common.nix
        ./hosts/beetroot/configuration.nix
      ];
    };
  }) //
  rec {
    nixopsConfigurations.default = with inputs.nixos-hardware.nixosModules; {
      nixpkgs = inputs.nixpkgs-stable-small;
      network = {
        description = "homelab";
        enableRollback = true;
        storage.legacy = { };
      };
      broccoli = { config, pkgs, ... }: {
        deployment.targetHost = "broccoli.home.arpa.";
        imports = [
          common-pc-ssd
          common-cpu-intel
          ./lib/nixops.nix
          ./hosts/broccoli/configuration.nix
        ];
      };
      rhubarb = { config, pkgs, ... }: {
        deployment.targetHost = "rhubarb.home.arpa.";
        imports = [
          raspberry-pi-4
          ./lib/nixops.nix
          ./hosts/rhubarb/configuration.nix
        ];
      };
      asparagus = { config, pkgs, ... }: {
        deployment.targetHost = "asparagus.home.arpa.";
        imports = [
          common-pc-ssd
          common-cpu-intel
          ./lib/nixops.nix
          ./hosts/asparagus/configuration.nix
        ];
      };
    };
  };

}
