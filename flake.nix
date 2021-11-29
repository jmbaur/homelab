{
  description = "NixOS configurations for homelab";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixpkgs.url = "nixpkgs/nixos-21.05";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , nixos-hardware
    , nixpkgs-unstable
    , neovim-nightly-overlay
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: {
      nixosConfigurations.beetroot = with nixos-hardware.nixosModules; nixpkgs-unstable.lib.nixosSystem {
        inherit system;
        modules = [
          common-pc-ssd
          common-cpu-amd
          common-gpu-amd
          common-pc-laptop-acpi_call
          lenovo-thinkpad
          ./hosts/beetroot/configuration.nix
          { nixpkgs.overlays = [ neovim-nightly-overlay.overlay ]; }
        ];
      };

      nixopsConfigurations.default = with nixos-hardware.nixosModules; {
        inherit nixpkgs;
        network = {
          description = "homelab";
          enableRollback = true;
          storage.legacy.databasefile = "~/.nixops/deployments.nixops";
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

      devShell =
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            gnumake
          ];
        };
    });

}
