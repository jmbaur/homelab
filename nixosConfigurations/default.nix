inputs: with inputs; {
  kale = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./kale
      ../modules/hardware/lx2k.nix
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
        users.users.root.password = "dontpwnme";
      })
    ];
  };

  rhubarb = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./rhubarb
      ../modules/hardware/rpi4.nix
      nixos-hardware.nixosModules.raspberry-pi-4
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  www = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./www
      self.nixosModules.default
      sops-nix.nixosModules.sops
      webauthn-tiny.nixosModules.default
    ];
  };
}
