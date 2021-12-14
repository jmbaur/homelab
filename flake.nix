{
  description = "NixOS configurations for homelab";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    git-get.url = "github:jmbaur/git-get";
    gosee.url = "github:jmbaur/gosee";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs-stable-small.url = "nixpkgs/nixos-21.11-small";
    nixpkgs.url = "github:jmbaur/nixpkgs?rev=50c1a826dca677b4b8751a05c98204218f20fced";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    promtop.url = "github:jmbaur/promtop";
    zig.url = "github:arqv/zig-overlay";
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
        storage.memory = { };
      };
      broccoli = { ... }: {
        deployment.targetHost = "broccoli.home.arpa.";
        imports = [
          common-pc-ssd
          common-cpu-intel
          ./lib/nixops.nix
          ./hosts/broccoli/configuration.nix
        ];
      };
      rhubarb = { ... }:
        let system = "aarch64-linux"; in
        {
          deployment.targetHost = "rhubarb.home.arpa.";
          nixpkgs.overlays = [ (self: super: { promtop = inputs.promtop.defaultPackage.${system}; }) ];
          # Allows for nixops to build for this system;
          nixpkgs.localSystem = { inherit system; config = "aarch64-unknown-linux-gnu"; };
          imports = [
            raspberry-pi-4
            ./lib/nixops.nix
            ./hosts/rhubarb/configuration.nix
          ];
        };
      asparagus = { ... }: {
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
