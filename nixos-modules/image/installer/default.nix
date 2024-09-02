{
  options,
  config,
  lib,
  pkgs,
  modulesPath,
  utils,
  ...
}:
let
  cfg = config.custom.image;

  installerCfg = cfg.installer;

  baseConfig = config;

  targetDeviceUnit = "${utils.escapeSystemdPath installerCfg.targetDisk}.device";
  sourceDeviceMount = "mnt.mount";

  noopService = {
    serviceConfig.ExecStart = [
      ""
      "/bin/true"
    ];
  };

  # Make the installer work with lots of common hardware.
  installerSystem = (
    pkgs.nixos (
      { config, ... }:
      let
        installer = pkgs.buildSimpleRustPackage "installer" ./installer.rs;
      in
      {
        imports = [ "${modulesPath}/profiles/all-hardware.nix" ];

        system.stateVersion = baseConfig.system.stateVersion;

        boot.kernelParams =
          let
            allowList = [ "^console=.*$" ];
          in
          lib.filter (
            param: lib.filter (allowRegex: lib.match allowRegex param != null) allowList != [ ]
          ) baseConfig.boot.kernelParams
          ++ [
            "installer.target_disk=${installerCfg.targetDisk}"
            "installer.source_disk=/dev/disk/by-partlabel/installer"
          ];

        # Firmware is used in the initrd when modules require it.
        hardware.firmware = lib.flatten options.hardware.firmware.definitions;

        boot.initrd = {
          # The image to install is kept on an ext4 filesystem, we add support
          # for other filesystems just for convenience.
          #
          # TODO(jared): Just write the compressed raw image to the partition
          # directly, no need for a filesystem.
          supportedFilesystems = [
            "ext4"
            "vfat"
          ];

          availableKernelModules = baseConfig.boot.initrd.availableKernelModules;
          kernelModules = baseConfig.boot.initrd.kernelModules;
          systemd = {
            enable = true;

            emergencyAccess = true;

            storePaths = [ installer ];
            initrdBin = [ pkgs.xz ];

            mounts = [
              {
                what = "/dev/disk/by-partlabel/installer";
                where = "/mnt";
                options = "ro";

                # Allow the installation medium to be unplugged prior to
                # unmount.
                mountConfig.ForceUnmount = true;
              }
            ];

            services = {
              # We aren't a full-blown nixos system, don't do nixos activation or
              # switch-root.
              initrd-nixos-activation = noopService;
              initrd-switch-root = noopService;
              initrd-cleanup = noopService;

              install-nixos = {
                requiredBy = [ "initrd.target" ];
                description = "NixOS Installation";
                unitConfig = {
                  OnFailure = [ "rescue.target" ];
                  OnSuccess = [ "reboot.target" ];
                };
                after = [
                  "initrd-fs.target"
                  "network.target"
                  targetDeviceUnit
                  sourceDeviceMount
                ];
                requires = [ targetDeviceUnit ];
                # systemd will kill this service when the device for this mount
                # is removed if we Require= this unit, so instead we put it in
                # wants.
                wants = [ sourceDeviceMount ];
                serviceConfig = {
                  Type = "oneshot";
                  StandardError = "tty";
                  StandardOutput = "tty";
                  ExecStart = toString [ (lib.getExe installer) ];
                };
              };
            };
          };
        };

        system.build = {
          installerUki = pkgs.callPackage (
            {
              lib,
              stdenv,
              systemdUkify,
            }:
            stdenv.mkDerivation {
              name = "installer-uki";
              nativeBuildInputs = [ systemdUkify ];
              buildCommand = ''
                ukify build \
                  --no-sign-kernel \
                  --efi-arch=${pkgs.stdenv.hostPlatform.efiArch} \
                  --uname=${installerSystem.config.system.build.kernel.version} \
                  --stub=${installerSystem.config.systemd.package}/lib/systemd/boot/efi/linux${pkgs.stdenv.hostPlatform.efiArch}.efi.stub \
                  --linux=${installerSystem.config.system.build.kernel}/${installerSystem.config.system.boot.loader.kernelFile} \
                  --cmdline="${toString config.boot.kernelParams}" \
                  --initrd=${config.system.build.initialRamdisk}/${installerSystem.config.system.boot.loader.initrdFile} \
                  --os-release=@${installerSystem.config.environment.etc."os-release".source} \
                  ${lib.optionalString installerSystem.config.hardware.deviceTree.enable "--devicetree=${installerSystem.config.hardware.deviceTree.package}/${installerSystem.config.hardware.deviceTree.name}"} \
                  --output=$out
              '';
            }
          ) { };

          blsEntry = pkgs.writeText "entry.conf" (
            ''
              title Installer
              linux /linux
              initrd /initrd
            ''
            + lib.optionalString config.hardware.deviceTree.enable ''
              devicetree /devicetree.dtb
            ''
            + ''
              options ${toString config.boot.kernelParams}
              architecture ${pkgs.stdenv.hostPlatform.efiArch}
            ''
          );
        };
      }
    )
  );
in
{
  options.custom.image.installer = with lib; {
    targetDisk = mkOption {
      type = types.path;
      description = ''
        The path to the block device that the image will be installed on.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    system.build = {
      installerInitrd = installerSystem.config.system.build.initialRamdisk;

      networkInstaller = throw "unimplemented";

      diskInstaller = pkgs.callPackage ./image.nix {
        imageName = config.networking.hostName;
        mainImage = "${config.system.build.image}/image.raw.xz";

        bootFileCommands =
          {
            "uefi" = ''
              echo ${installerSystem.config.system.build.installerUki}:/EFI/boot/boot${pkgs.stdenv.hostPlatform.efiArch}.efi >>$bootfiles
            '';
            "bootLoaderSpec" =
              ''
                echo ${installerSystem.config.system.build.blsEntry}:/loader/entries/installer.conf >>$bootfiles
                echo ${installerSystem.config.system.build.kernel}/${installerSystem.config.system.boot.loader.kernelFile}:/linux >>$bootfiles
                echo ${installerSystem.config.system.build.initialRamdisk}/${installerSystem.config.system.boot.loader.initrdFile}:/initrd >>$bootfiles
              ''
              + lib.optionalString config.hardware.deviceTree.enable ''
                echo ${installerSystem.config.hardware.deviceTree.package}/${installerSystem.config.hardware.deviceTree.name}:/devicetree.dtb >>$bootfiles
              '';
            "uboot" = throw "uboot not yet supported for disk installer";
          }
          ."${lib.head (lib.attrNames cfg.boot)}";

        # TODO(jared): We assume the sector size of the installation media is
        # 512, I have yet to see a USB stick with a different sector size...
        sectorSize = 512;
      };
    };
  };
}
