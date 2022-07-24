inputs: with inputs; {
  broccoli = nixpkgs.lib.nixosSystem rec {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      inherit (homelab-private) secrets;
      inherit (self.inventory.${system}) inventory;
    };
    modules = [
      ./hosts/broccoli/configuration.nix
      agenix.nixosModules.age
      homelab-private.nixosModules.common
      ipwatch.nixosModules.default
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.supermicro
      { nixpkgs.overlays = [ ipwatch.overlays.default ]; }
    ];
  };

  beetroot = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./hosts/beetroot/configuration.nix
      homelab-private.nixosModules.common
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.lenovo-thinkpad-t495
    ];
  };

  okra = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./hosts/okra/configuration.nix
      homelab-private.nixosModules.common
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.intel-nuc-8i7beh
    ];
  };

  asparagus = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./hosts/asparagus/configuration.nix
      homelab-private.nixosModules.common
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.common-cpu-amd
      nixos-hardware.nixosModules.common-gpu-amd
    ];
  };

  website = nixpkgs.lib.nixosSystem rec {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; inherit (self.inventory.${system}) inventory; };
    modules = [
      ./vms/website.nix
      microvm.nixosModules.microvm
    ];
  };

  kale = nixpkgs.lib.nixosSystem rec {
    system = "x86_64-linux";
    specialArgs = { inherit (self.inventory.${system}) inventory; };
    modules = [
      ./hosts/kale/configuration.nix
      agenix.nixosModules.age
      homelab-private.nixosModules.common
      microvm.nixosModules.host
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.common-cpu-amd
      self.nixosModules.default
      { microvm.vms = { website.flake = self; }; }
    ];
  };

  kale2 = nixpkgs.lib.nixosSystem rec {
    system = "aarch64-linux";
    specialArgs = { inherit (self.inventory.${system}) inventory; };
    modules = [
      # microvm.nixosModules.host
      # { microvm.vms = { website.flake = self; }; }
      ./hosts/kale2/configuration.nix
      agenix.nixosModules.age
      homelab-private.nixosModules.common
      nixos-configs.nixosModules.default
      self.nixosModules.default
    ];
  };

  artichoke = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
      ./hosts/artichoke/configuration.nix
      homelab-private.nixosModules.common
      nixos-configs.nixosModules.default
      self.nixosModules.default
      # This is here since the sdImage options do not exist without importing
      # the sd-image-aarch64.nix module.
      ({ config, lib, ... }: {
        sdImage.postBuildCommands =
          lib.optionalString (config.hardware.cn913x.enable && config.hardware.cn913x.withUboot)
            "dd if=${pkgs.armTrustedFirmwareCN9130_CF_Pro}/flash-image.bin of=$img bs=512 seek=4096 conv=notrunc";
      })
    ];
  };

  rhubarb = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
      ./hosts/rhubarb/configuration.nix
      homelab-private.nixosModules.common
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.raspberry-pi-4
      self.nixosModules.default
    ];
  };
}
