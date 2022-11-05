inputs: with inputs; {
  beetroot = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      inherit (homelab-private) secrets;
    };
    modules = [
      ./beetroot
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.lenovo-thinkpad-t495
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  potato = nixpkgs.lib.nixosSystem rec {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      inherit (self.inventory.${system}) inventory;
    };
    modules = [
      ./potato/configuration.nix
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.common-cpu-amd
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  kale = nixpkgs.lib.nixosSystem rec {
    system = "aarch64-linux";
    specialArgs = {
      inherit inputs;
      inherit (self.inventory.${system}) inventory;
      inherit (homelab-private) secrets;
    };
    modules = [
      ./kale
      ../modules/hardware/lx2k.nix
      nixos-configs.nixosModules.default
      runner-nix.nixosModules.default
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  artichoke-test = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ../modules/hardware/a38x.nix
      self.nixosModules.default
      ({ lib, ... }: {
        system.stateVersion = "22.11";
        nixpkgs.crossSystem = lib.systems.examples.armv7l-hf-multiplatform;
        custom.disableZfs = true;
      })
    ];
  };

  artichoke = nixpkgs.lib.nixosSystem rec {
    system = "aarch64-linux";
    specialArgs = {
      inherit inputs;
      inherit (homelab-private) secrets;
      inherit (self.inventory.${system}) inventory;
    };
    modules = [
      ./artichoke
      ../modules/hardware/cn913x.nix
      ipwatch.nixosModules.default
      nixos-configs.nixosModules.default
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  rhubarb = nixpkgs.lib.nixosSystem rec {
    system = "aarch64-linux";
    specialArgs = {
      inherit inputs;
      inherit (homelab-private) secrets;
      inherit (self.inventory.${system}) inventory;
    };
    modules = [
      ./rhubarb
      ../modules/hardware/rpi4.nix
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.raspberry-pi-4
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  www = nixpkgs.lib.nixosSystem rec {
    system = "aarch64-linux";
    specialArgs = {
      inherit inputs;
      inherit (self.inventory.${system}) inventory;
    };
    modules = [
      ./www
      nixos-configs.nixosModules.default
      self.nixosModules.default
      sops-nix.nixosModules.sops
      webauthn-tiny.nixosModules.default
    ];
  };
}
