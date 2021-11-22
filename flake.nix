{
  description = "NixOS configurations for homelab";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    nixpkgs-stable.url = github:nixos/nixpkgs/nixos-21.05;
    nixos-hardware.url = github:NixOS/nixos-hardware/master;
  };

  outputs = { self, nixpkgs, nixpkgs-stable, nixos-hardware }: {

    nixosConfigurations.beetroot = with nixos-hardware.nixosModules; nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        common-pc-ssd
        common-cpu-amd
        common-gpu-amd
        common-pc-laptop-acpi_call
        lenovo-thinkpad
        ./hosts/beetroot/configuration.nix
      ];
    };

    nixopsConfigurations.default = with nixos-hardware.nixosModules; {
      nixpkgs = nixpkgs-stable;
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
