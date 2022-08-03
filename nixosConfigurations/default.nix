inputs: with inputs; {
  beetroot = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./beetroot/configuration.nix
      homelab-private.nixosModules.common
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.lenovo-thinkpad-t495
    ];
  };

  okra = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./okra/configuration.nix
      homelab-private.nixosModules.common
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.intel-nuc-8i7beh
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

  potato = nixpkgs.lib.nixosSystem rec {
    system = "x86_64-linux";
    specialArgs = { inherit (self.inventory.${system}) inventory; };
    modules = [
      ./potato/configuration.nix
      agenix.nixosModules.age
      homelab-private.nixosModules.common
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.common-cpu-amd
      self.nixosModules.default
    ];
  };

  kale = nixpkgs.lib.nixosSystem rec {
    system = "aarch64-linux";
    specialArgs = { inherit (self.inventory.${system}) inventory; };
    modules = [
      ./kale/configuration.nix
      agenix.nixosModules.age
      homelab-private.nixosModules.common
      nixos-configs.nixosModules.default
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
      # TODO(jared): Put this in when ATF build works.
      # ({pkgs, ...}:{ sdImage.postBuildCommands = "dd if=${pkgs.armTrustedFirmwareCN9130_CF_Pro}/flash-image.bin of=$img bs=512 seek=4096 conv=notrunc"; })
      ./artichoke/configuration.nix
      agenix.nixosModules.age
      homelab-private.nixosModules.common
      ipwatch.nixosModules.default
      nixos-configs.nixosModules.default
      self.nixosModules.default
      { nixpkgs.overlays = [ ipwatch.overlays.default ]; }
    ];
  };

  rhubarb = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
      ./rhubarb/configuration.nix
      homelab-private.nixosModules.common
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.raspberry-pi-4
      self.nixosModules.default
    ];
  };
}
