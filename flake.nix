{
  description = "NixOS configurations for homelab";

  inputs = {
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs-stable-small.url = "nixpkgs/nixos-21.11-small";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs =
    { self
    , neovim-nightly-overlay
    , nixos-hardware
    , nixpkgs-stable-small
    , nixpkgs
    , pre-commit-hooks
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      src = builtins.path { path = ./.; };
    in
    rec {
      devShell.${system} = pkgs.mkShell {
        buildInputs = with pkgs;[ git gnumake ];
      };
      checks.${system}.pre-commit-check = pre-commit-hooks.lib.${system}.run {
        inherit src;
        hooks.nixpkgs-fmt.enable = true;
      };
      nixosConfigurations.beetroot = with nixos-hardware.nixosModules; nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          common-pc-ssd
          common-cpu-amd
          common-gpu-amd
          common-pc-laptop-acpi_call
          lenovo-thinkpad
          { nixpkgs.overlays = [ neovim-nightly-overlay.overlay ]; }
          ./hosts/beetroot/configuration.nix
        ];
      };

      nixopsConfigurations.default = with nixos-hardware.nixosModules; {
        nixpkgs = nixpkgs-stable-small;
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
