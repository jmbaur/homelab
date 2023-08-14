inputs:
let
  inherit (inputs.nixpkgs.lib) nixosSystem;

  mkInstaller = { modules ? [ ] }: nixosSystem {
    modules = [
      inputs.self.nixosModules.default
      ({ ... }: {
        custom.installer.enable = true;
      })
    ] ++ modules;
  };

  mkInstallerISO = { modules ? [ ] }: mkInstaller {
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
    modules = with inputs; [ ./artichoke self.nixosModules.default ];
  };

  squash = nixosSystem {
    modules = with inputs; [
      ./squash
      ipwatch.nixosModules.default
      self.nixosModules.default
      nixos-router.nixosModules.default
    ];
  };

  potato = nixosSystem {
    modules = with inputs; [
      ./potato
      lanzaboote.nixosModules.lanzaboote
      self.nixosModules.default
      nixos-hardware.nixosModules.lenovo-thinkpad-t480
    ];
  };

  beetroot = nixosSystem {
    modules = with inputs; [ ./beetroot self.nixosModules.default ];
  };

  carrot = nixosSystem {
    modules = with inputs; [ ./carrot self.nixosModules.default ];
  };

  kale = nixosSystem {
    modules = with inputs; [
      ./kale
      runner-nix.nixosModules.default
      self.nixosModules.default
    ];
  };

  fennel = nixosSystem {
    modules = with inputs; [ self.nixosModules.default ./fennel ];
  };

  rhubarb = nixosSystem {
    modules = with inputs; [
      ./rhubarb
      nixos-hardware.nixosModules.raspberry-pi-4
      self.nixosModules.default
    ];
  };

  www = nixosSystem {
    modules = with inputs; [
      ./www
      self.nixosModules.default
      webauthn-tiny.nixosModules.default
    ];
  };

  installer_iso_x86_64-linux = mkInstallerISO { modules = [{ nixpkgs.hostPlatform = "x86_64-linux"; }]; };
  installer_iso_aarch64-linux = mkInstallerISO {
    modules = [
      ({ config, ... }: {
        nixpkgs.hostPlatform = "aarch64-linux";
        isoImage.contents = [{
          source = "${config.boot.kernelPackages.kernel}/dtbs";
          target = "boot/dtbs";
        }];
      })
    ];
  };

  installer_iso_lx2k = mkInstallerISO {
    modules = [
      ({
        nixpkgs.hostPlatform = "aarch64-linux";
        hardware.lx2k.enable = true;
      })
    ];
  };

  installer_sd_image_x86_64-linux = mkInstaller {
    modules = [
      ({ modulesPath, ... }: {
        nixpkgs.hostPlatform = "x86_64-linux";
        imports = [
          "${modulesPath}/installer/sd-card/sd-image-x86_64.nix"
        ];
      })
    ];
  };
  installer_sd_image_aarch64-linux = mkInstaller {
    modules = [
      ({ modulesPath, ... }: {
        nixpkgs.hostPlatform = "aarch64-linux";
        imports = [
          "${modulesPath}/installer/sd-card/sd-image-aarch64-installer.nix"
        ];
      })
    ];
  };

  installer_sd_image_kukui_fennel14 = mkInstaller {
    modules = [
      ../nixos-modules/depthcharge/sd-image.nix
      ({ ... }: {
        nixpkgs.hostPlatform = "aarch64-linux";
        boot.loader.depthcharge.enable = true;
        boot.initrd.systemd.enable = true;
        hardware.kukui-fennel14.enable = true;
      })
    ];
  };

  installer_sd_image_cn9130_clearfog = mkInstaller {
    modules = [
      ({ modulesPath, ... }: {
        disabledModules = [
          # prevent initrd from requiring a bunch of kernel modules we don't
          # need
          "${modulesPath}/profiles/all-hardware.nix"
        ];
        imports = [ "${modulesPath}/installer/sd-card/sd-image-aarch64-installer.nix" ];
        nixpkgs.hostPlatform = "aarch64-linux";
        boot.initrd.systemd.enable = true;
        hardware.clearfog-cn913x.enable = true;
        custom.crossCompile.enable = true;
      })
    ];
  };

  installer_sd_image_asurada_spherion = mkInstaller {
    modules = [
      ../nixos-modules/depthcharge/sd-image.nix
      ({ ... }: {
        nixpkgs.hostPlatform = "aarch64-linux";
        boot.loader.depthcharge.enable = true;
        boot.initrd.systemd.enable = true;
        hardware.asurada-spherion.enable = true;
      })
    ];
  };

  bpi-r3-installer = mkInstaller {
    modules = [
      ../nixos-modules/sd-image.nix
      ({ ... }: {
        nixpkgs.hostPlatform = "aarch64-linux";
        hardware.bpi-r3.enable = true;
        custom.server.enable = true; # limits packages needed for cross-compilation
        custom.crossCompile.enable = true;
        custom.disableZfs = true;
      })
    ];
  };

  armada-388-clearfog-installer = mkInstaller {
    modules = [
      ({ config, pkgs, modulesPath, ... }: {
        disabledModules = [
          # prevent initrd from requiring a bunch of kernel modules we don't
          # have with the armada 388's kernel mvebu_v7_defconfig
          "${modulesPath}/profiles/all-hardware.nix"
        ];
        imports = [
          "${modulesPath}/profiles/installation-device.nix"
          "${modulesPath}/installer/sd-card/sd-image.nix"
        ];
        hardware.armada-a38x.enable = true;
        networking.useNetworkd = true;
        custom.server.enable = true;
        custom.crossCompile.enable = true;
        custom.disableZfs = true;
        sdImage.populateFirmwareCommands = "";
        sdImage.populateRootCommands = ''
          mkdir -p ./files/boot
          ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
        '';
        sdImage.postBuildCommands = ''
          dd if=${pkgs.ubootClearfog}/u-boot-with-spl.kwb of=$img bs=512 seek=1 conv=notrunc
        '';
      })
    ];
  };
}
