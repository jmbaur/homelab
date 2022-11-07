inputs: with inputs; {
  beetroot = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./beetroot
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.lenovo-thinkpad-t495
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  kale = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
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
    system = "armv7l-linux";
    modules = [
      ../modules/hardware/a38x.nix
      self.nixosModules.default
      ({ ... }: {
        system.stateVersion = "22.11";
        custom.disableZfs = true;
      })
    ];
  };

  rhubarb = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./rhubarb
      ../modules/hardware/rpi4.nix
      nixos-configs.nixosModules.default
      nixos-hardware.nixosModules.raspberry-pi-4
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  www = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./www
      nixos-configs.nixosModules.default
      self.nixosModules.default
      sops-nix.nixosModules.sops
      webauthn-tiny.nixosModules.default
    ];
  };
}
