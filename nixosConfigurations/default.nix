inputs: with inputs; {
  dev = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      nixos-wsl.nixosModules.wsl
      self.nixosModules.default
      ({
        networking.hostName = "dev";
        custom = {
          users.jared = {
            enable = true;
            passwordFile = null;
          };
          dev.enable = true;
        };
        users.mutableUsers = true;
        system.stateVersion = "22.11";
        wsl = {
          enable = true;
          wslConf.automount.root = "/mnt";
          defaultUser = "jared";
          startMenuLaunchers = true;
          nativeSystemd = true;
        };
      })
    ];
  };

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
