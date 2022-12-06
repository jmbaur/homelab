inputs: with inputs;
let
  installer_iso = { system, extraModules ? [ ] }: nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      self.nixosModules.default
      ({ modulesPath, ... }: {
        imports = [
          "${modulesPath}/installer/cd-dvd/channel.nix"
          "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
        ];
        custom.installer.enable = true;
      })
    ] ++ extraModules;
  };

  installer_sd_image = { system, extraModules ? [ ] }: nixpkgs.lib.nixosSystem {
    inherit system;
    modules = [
      self.nixosModules.default
      ({ modulesPath, ... }: {
        imports = [ "${modulesPath}/installer/sd-card/sd-image-aarch64-installer.nix" ];
        custom.installer.enable = true;
      })
    ] ++ extraModules;
  };
in
{
  artichoke = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./artichoke
      ipwatch.nixosModules.default
      self.nixosModules.router
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
      runner-nix.nixosModules.default
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  fennel = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [ self.nixosModules.default ./fennel ];
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

  clearfog-a38x-test = nixpkgs.lib.nixosSystem {
    system = "armv7l-linux";
    modules = [
      self.nixosModules.default
      ({ lib, pkgs, modulesPath, ... }: {
        imports = [ "${modulesPath}/installer/sd-card/sd-image-armv7l-multiplatform.nix" ];
        hardware.clearfog-a38x.enable = true;
        sdImage.postBuildCommands = ''
          dd if=${pkgs.ubootClearfog}/u-boot-spl.kwb of=$img bs=512 seek=1 conv=sync
        '';
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

  installer_iso_x86_64-linux = installer_iso { system = "x86_64-linux"; };
  installer_iso_aarch64-linux = installer_iso { system = "aarch64-linux"; };

  installer_iso_lx2k = installer_iso {
    system = "aarch64-linux";
    extraModules = [ ({ hardware.lx2k.enable = true; }) ];
  };

  installer_sd_image = installer_sd_image { system = "aarch64-linux"; };

  installer_sd_image_kukui_fennel14 = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      self.nixosModules.default
      ({ modulesPath, ... }: {
        boot.loader.depthcharge.enable = true;
        boot.initrd.systemd.enable = true;
        hardware.kukui-fennel14.enable = true;
        custom.installer.enable = true;
        custom.remoteBuilders.aarch64builder.enable = true;
        imports = [
          ../nixosModules/depthcharge/sd-image.nix
          "${modulesPath}/profiles/base.nix"
          "${modulesPath}/profiles/installation-device.nix"
        ];
      })
    ];
  };
}
