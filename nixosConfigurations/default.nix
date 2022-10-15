inputs: with inputs; {
  okra = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      inherit (homelab-private) secrets;
    };
    modules = [
      ./okra
      agenix.nixosModules.age
      self.nixosModules.default
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.intel-nuc-8i7beh
    ];
  };

  carrot = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      inherit (homelab-private) secrets;
    };
    modules = [
      ./carrot
      agenix.nixosModules.age
      self.nixosModules.default
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.lenovo-thinkpad-t495
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
      agenix.nixosModules.age
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.common-cpu-amd
      self.nixosModules.default
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
      agenix.nixosModules.age
      nixos-configs.nixosModules.default
      runner-nix.nixosModules.default
      self.nixosModules.default
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
      "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
      ./artichoke
      agenix.nixosModules.age
      ipwatch.nixosModules.default
      nixos-configs.nixosModules.default
      self.nixosModules.default
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
      "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
      ./rhubarb
      agenix.nixosModules.age
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.raspberry-pi-4
      self.nixosModules.default
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
      agenix.nixosModules.age
      nixos-configs.nixosModules.default
      self.nixosModules.default
      webauthn-tiny.nixosModules.default
      ({ lib, ... }: {
        nixpkgs.overlays = lib.mkAfter [
          (_: prev: {
            inherit (import prev.path {
              localSystem = "x86_64-linux";
              crossSystem = "aarch64-linux";
              overlays = [ webauthn-tiny.overlays.default ];
            }) webauthn-tiny;
          })
        ];
      })
    ];
  };
}
