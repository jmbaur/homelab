inputs: with inputs; {
  beetroot = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./beetroot
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
      runner-nix.nixosModules.default
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  lxc-test = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      "${nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
      ({
        system.stateVersion = "22.11";
      })
    ];
  };

  netboot-test = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      "${nixpkgs}/nixos/modules/installer/netboot/netboot-minimal.nix"
      ({
        system.stateVersion = "22.11";
        users.users.root.password = "dontpwnme";
      })
    ];
  };

  artichoke-test = nixpkgs.lib.nixosSystem {
    system = "armv7l-linux";
    modules = [
      ../modules/hardware/a38x.nix
      self.nixosModules.default
      ({ lib, pkgs, ... }: {
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
        system.stateVersion = "22.11";
        custom.common.enable = lib.mkForce false;
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

  okra = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ ./okra self.nixosModules.default ];
  };
}
