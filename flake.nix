{
  description = "NixOS configurations for homelab";

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
        checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = builtins.path { path = ./.; };
          hooks.nixpkgs-fmt.enable = true;
        };
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ git gnumake nixopsUnstable ] ++
            pkgs.lib.singleton inputs.deploy-rs.defaultPackage.${system};
          inherit (checks.pre-commit-check) shellHook;
        };
        packages.p = pkgs.callPackage ./pkgs/p.nix { };
      }) // {
    nixopsConfigurations.default = with inputs.nixos-hardware.nixosModules; {
      nixpkgs = inputs.nixpkgs;
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
          nixpkgs.overlays = [ promtop.overlay.${system} ];
          # Allows for nixops to build for this system;
          nixpkgs.localSystem = {
            inherit system;
            config = "aarch64-unknown-linux-gnu";
          };
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
