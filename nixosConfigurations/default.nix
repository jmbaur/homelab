inputs:
let
  nixosSystem = args: inputs.nixpkgs.lib.nixosSystem (inputs.nixpkgs.lib.recursiveUpdate
    {
      modules = [{ nix.registry.nixpkgs.flake = inputs.nixpkgs; }];
    }
    args);
  mkInstaller = { system, modules ? [ ] }: nixosSystem {
    inherit system;
    modules = [
      inputs.self.nixosModules.default
      ({ config, ... }: {
        custom.installer.enable = true;
        custom.remoteBuilders.aarch64builder.enable = config.nixpkgs.system == "aarch64-linux";
      })
    ] ++ modules;
  };

  mkInstallerISO = { system, modules ? [ ] }: mkInstaller {
    inherit system;
    modules = [
      ({ modulesPath, ... }: {
        imports = [
          "${modulesPath}/installer/cd-dvd/channel.nix"
          "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
        ];
      })
    ] ++ modules;
  };
in
{
  artichoke = nixosSystem {
    system = "aarch64-linux";
    modules = with inputs; [
      ./artichoke
      ipwatch.nixosModules.default
      self.nixosModules.default
      nixos-router.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  squash = nixosSystem {
    system = "armv7l-linux";
    modules = with inputs; [
      ./squash
      self.nixosModules.default
    ];
  };

  beetroot = nixosSystem {
    system = "x86_64-linux";
    modules = with inputs; [
      ./beetroot
      self.nixosModules.default
      sops-nix.nixosModules.sops
      ({ modulesPath, ... }: {
        disabledModules = [ "${modulesPath}/system/boot/loader/generic-extlinux-compatible" ];
        imports = [ "${nixpkgs-extlinux-specialisation}/nixos/modules/system/boot/loader/generic-extlinux-compatible" ];
      })
    ];
  };

  kale = nixosSystem {
    system = "aarch64-linux";
    modules = with inputs; [
      ./kale
      runner-nix.nixosModules.default
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  fennel = nixosSystem {
    system = "aarch64-linux";
    modules = with inputs; [ self.nixosModules.default ./fennel ];
  };

  lxc-test = nixosSystem {
    system = "aarch64-linux";
    modules = [
      "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
      ({
        system.stateVersion = "22.11";
      })
    ];
  };

  netboot-test = nixosSystem {
    system = "aarch64-linux";
    modules = [
      ({ modulesPath, ... }: {
        imports = [ "${modulesPath}/installer/netboot/netboot-minimal.nix" ];
        system.stateVersion = "23.05";
        users.users.root.password = "dontpwnme";
      })
    ];
  };

  potato = nixosSystem {
    system = "x86_64-linux";
    modules = [ ./potato ];
  };

  rhubarb = nixosSystem {
    system = "aarch64-linux";
    modules = with inputs; [
      ./rhubarb
      nixos-hardware.nixosModules.raspberry-pi-4
      self.nixosModules.default
      sops-nix.nixosModules.sops
    ];
  };

  www = nixosSystem {
    system = "aarch64-linux";
    modules = with inputs; [
      ./www
      self.nixosModules.default
      sops-nix.nixosModules.sops
      webauthn-tiny.nixosModules.default
    ];
  };

  okra = nixosSystem {
    system = "x86_64-linux";
    modules = with inputs; [ ./okra self.nixosModules.default ];
  };

  installer_iso_x86_64-linux = mkInstallerISO { system = "x86_64-linux"; };
  installer_iso_aarch64-linux = mkInstallerISO {
    system = "aarch64-linux";
    modules = [
      ({ config, ... }: {
        boot.loader.grub.extraFiles.dtbs = "${config.boot.kernelPackages.kernel}/dtbs";
      })
    ];
  };

  installer_iso_lx2k = mkInstallerISO {
    system = "aarch64-linux";
    modules = [ ({ hardware.lx2k.enable = true; }) ];
  };

  installer_sd_image_x86_64-linux = mkInstaller {
    system = "x86_64-linux";
    modules = [
      ({ modulesPath, ... }: {
        imports = [
          "${modulesPath}/profiles/installation-device.nix"
          "${modulesPath}/installer/sd-card/sd-image-x86_64.nix"
        ];
      })
    ];
  };
  installer_sd_image_aarch64-linux = mkInstaller {
    system = "aarch64-linux";
    modules = [
      ({ modulesPath, ... }: {
        imports = [
          "${modulesPath}/installer/sd-card/sd-image-aarch64-installer.nix"
        ];
      })
    ];
  };

  installer_sd_image_kukui_fennel14 = mkInstaller {
    system = "aarch64-linux";
    modules = [
      ../nixosModules/depthcharge/sd-image.nix
      ({ ... }: {
        boot.loader.depthcharge.enable = true;
        boot.initrd.systemd.enable = true;
        hardware.kukui-fennel14.enable = true;
      })
    ];
  };

  installer_sd_image_cn9130_clearfog = mkInstaller {
    system = "aarch64-linux";
    modules = [
      ({ modulesPath, ... }: {
        disabledModules = [
          # prevent initrd from requiring a bunch of kernel modules we don't
          # need
          "${modulesPath}/profiles/all-hardware.nix"
        ];
        imports = [ "${modulesPath}/installer/sd-card/sd-image-aarch64-installer.nix" ];
        boot.initrd.systemd.enable = true;
        hardware.clearfog-cn913x.enable = true;
      })
    ];
  };

  installer_sd_image_asurada_spherion = mkInstaller {
    system = "aarch64-linux";
    modules = [
      ../nixosModules/depthcharge/sd-image.nix
      ({ ... }: {
        boot.loader.depthcharge.enable = true;
        boot.initrd.systemd.enable = true;
        hardware.asurada-spherion.enable = true;
      })
    ];
  };

  armada-388-clearfog-installer = mkInstaller {
    system = "armv7l-linux";
    modules = [
      ({ config, pkgs, modulesPath, ... }: {
        disabledModules = [
          # prevent initrd from requiring a bunch of kernel modules we don't
          # have with the armada 388's kernel defconfig
          "${modulesPath}/profiles/all-hardware.nix"
        ];
        imports = [
          "${modulesPath}/profiles/installation-device.nix"
          "${modulesPath}/installer/sd-card/sd-image.nix"
        ];
        hardware.armada-a38x.enable = true;
        networking.useNetworkd = true;
        custom.server.enable = true;
        custom.disableZfs = true;
        sdImage.populateFirmwareCommands = "";
        sdImage.populateRootCommands = ''
          mkdir -p ./files/boot
          ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
        '';
        sdImage.postBuildCommands = ''
          dd if=${pkgs.ubootClearfog}/u-boot-spl.kwb of=$img bs=512 seek=1 conv=notrunc
        '';
      })
    ];
  };
}
