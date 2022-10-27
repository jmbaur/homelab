inputs: with inputs; {
  carrot = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      inherit (homelab-private) secrets;
    };
    modules = [
      ./carrot
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
      nixos-configs.nixosModules.default
      runner-nix.nixosModules.default
      self.nixosModules.default
      sops-nix.nixosModules.sops
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
      "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
      ./rhubarb
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
