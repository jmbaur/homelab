{
  description = "NixOS configurations for homelab";

  inputs = {
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "nixpkgs/nixos-21.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, ... }@inputs: rec {

    nixosConfigurations.beetroot = with inputs.nixos-hardware.nixosModules; inputs.nixpkgs-unstable.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        common-pc-ssd
        common-cpu-amd
        common-gpu-amd
        common-pc-laptop-acpi_call
        lenovo-thinkpad
        ./hosts/beetroot/configuration.nix
        { nixpkgs.overlays = [ inputs.neovim-nightly-overlay.overlay ]; }
      ];
    };

    nixopsConfigurations.default = with inputs.nixos-hardware.nixosModules; {
      nixpkgs = inputs.nixpkgs;
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

  };
}
