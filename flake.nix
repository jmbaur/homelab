{
  description = "NixOS configurations for homelab";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-utils.url = "github:numtide/flake-utils";
    git-get.url = "github:jmbaur/git-get";
    gosee.url = "github:jmbaur/gosee";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs-stable-small.url = "nixpkgs/nixos-21.11-small";
    nixpkgs.url = "github:jmbaur/nixpkgs/fido2luks-pin"; # pinned on latest commits from this branch
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    promtop.url = "github:jmbaur/promtop";
    zig.url = "github:arqv/zig-overlay";
  };

  outputs = inputs: inputs.flake-utils.lib.eachSystem inputs.flake-utils.lib.allSystems
    (system:
      let pkgs = inputs.nixpkgs-stable-small.legacyPackages.${system}; in
      rec {
        checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = builtins.path { path = ./.; };
          hooks.nixpkgs-fmt.enable = true;
        };
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ git gnumake ];
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
              deploy-rs = inputs.deploy-rs.defaultPackage.${system}; # TODO(jared): use overlay defined in flake
              git-get = inputs.git-get.defaultPackage.${system};
              gosee = inputs.gosee.defaultPackage.${system};
            })
          ];
        })
        ./config
        ./lib/common.nix
        ./hosts/beetroot/configuration.nix
      ];
    };
  }) // {
    nixopsConfigurations.default = with inputs.nixos-hardware.nixosModules; {
      nixpkgs = inputs.nixpkgs-stable-small;
      network = {
        description = "homelab";
        enableRollback = true;
        storage.legacy = { };
      };
      broccoli = { ... }: {
        deployment.targetHost = "broccoli.home.arpa.";
        imports = [
          common-pc-ssd
          common-cpu-intel
          ./lib/nixops.nix
          ./lib/supermicro.nix
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
      spinach = { ... }: {
        deployment.targetHost = "spinach.home.arpa.";
        imports = [
          # common-pc-ssd # TODO(jared): enable this?
          common-cpu-intel
          ./lib/nixops.nix
          ./lib/supermicro.nix
          ./hosts/spinach/configuration.nix
        ];
      };
    };
  };
}
