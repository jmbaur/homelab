{
  config,
  lib,
  pkgs,
  extendModules,
  modulesPath,
  ...
}:
let
  cfg = config.custom.image;

  # Make the installer work with lots of common hardware.
  installerSystem = extendModules { modules = [ "${modulesPath}/profiles/all-hardware.nix" ]; };

  # Determine the set of modules that we need to mount the root FS.
  modulesClosure = pkgs.makeModulesClosure {
    rootModules =
      installerSystem.config.boot.initrd.availableKernelModules
      ++ installerSystem.config.boot.initrd.kernelModules;
    kernel = installerSystem.config.system.modulesTree;
    inherit (installerSystem.config.hardware) firmware;

    # If we stop importing all-harware.nix, we could remove this.
    allowMissing = true;
  };

  installerEnv = pkgs.buildEnv {
    name = "installer-bin-env";
    paths = [
      (pkgs.busybox.override {
        # module utilities provided by kmod
        extraConfig = ''
          CONFIG_INSMOD n
          CONFIG_LSMOD n
          CONFIG_MODINFO n
          CONFIG_MODPROBE n
          CONFIG_RMMOD n
        '';
      })
      modulesClosure
      pkgs.systemdMinimal
      pkgs.systemdMinimal.kmod
      pkgs.systemdMinimal.kmod.lib
      (pkgs.buildSimpleRustPackage "installer" ./installer.rs)
    ];
    pathsToLink = [
      "/bin"
      "/sbin"
      "/lib"
    ];
  };

  installerCfg = config.custom.image.installer;

  startupScript = pkgs.writeScript "installer-startup-script" ''
    #!/bin/sh

    mkdir -p /proc && mount -t proc proc /proc
    mkdir -p /sys && mount -t sysfs sysfs /sys
    mkdir -p /dev && mount -t devtmpfs devtmpfs /dev
    mkdir -p /dev/pts && mount -t devpts devpts /dev/pts
    mkdir -p /run && mount -t tmpfs tmpfs /run

    # copied from NixOS stage-1-init.sh
    mkdir -p /etc/udev
    touch /etc/fstab # to shut up mount
    ln -s /proc/mounts /etc/mtab # to shut up mke2fs
    touch /etc/udev/hwdb.bin # to shut up udev
    touch /etc/initrd-release

    for i in ${toString installerSystem.config.boot.initrd.kernelModules}; do
      /sbin/modprobe $i
    done

    ln -sfn /proc/self/fd /dev/fd
    ln -sfn /proc/self/fd/0 /dev/stdin
    ln -sfn /proc/self/fd/1 /dev/stdout
    ln -sfn /proc/self/fd/2 /dev/stderr
    mkdir -p /etc/systemd
  '';

  installerKernelParams = installerSystem.config.boot.kernelParams ++ [
    "installer.target_disk=${installerCfg.targetDisk}"
    "installer.source_disk=/dev/disk/by-partlabel/installer"
  ];

  installerInitialRamdisk = pkgs.makeInitrdNG {
    name = "installer-initrd";
    inherit (config.boot.initrd) compressor compressorArgs prepend;
    strip = true;

    contents = [
      {
        source = "${installerEnv}/bin/busybox";
        target = "/init";
      }
      {
        source = installerEnv;
        target = "/usr";
      }
      {
        source = "${installerEnv}/lib";
        target = "/lib";
      }
      {
        source = "${installerEnv}/bin";
        target = "/bin";
      }
      {
        source = "${installerEnv}/sbin";
        target = "/sbin";
      }
      {
        source = startupScript;
        target = "/etc/init.d/rcS";
      }
      {
        source = ./inittab;
        target = "/etc/inittab";
      }
    ];
  };

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
          --cmdline="${toString installerKernelParams}" \
          --initrd=${installerInitialRamdisk}/${installerSystem.config.system.boot.loader.initrdFile} \
          --os-release=@${installerSystem.config.environment.etc."os-release".source} \
          ${lib.optionalString installerSystem.config.hardware.deviceTree.enable "--devicetree=${installerSystem.config.hardware.deviceTree.package}/${installerSystem.config.hardware.deviceTree.name}"} \
          --output=$out
      '';
    }
  ) { };

  installerBlsEntry = pkgs.writeText "entry.conf" (
    ''
      title Installer
      linux /linux
      initrd /initrd
    ''
    + lib.optionalString config.hardware.deviceTree.enable ''
      devicetree /devicetree.dtb
    ''
    + ''
      options ${toString installerKernelParams}
      architecture ${pkgs.stdenv.hostPlatform.efiArch}
    ''
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
    # The image to install is kept on an ext4 filesystem, we add support for
    # other filesystems just for convenience. TODO(jared): just write the
    # compressed raw image to the partition directly, no need for a filesystem.
    boot.initrd.supportedFilesystems = [
      "ext4"
      "vfat"
    ];

    system.build = {
      networkInstaller = throw "unimplemented";

      diskInstaller = pkgs.callPackage ./image.nix {
        imageName = config.networking.hostName;
        mainImage = "${config.system.build.image}/image.raw.xz";

        bootFileCommands =
          {
            "uefi" = ''
              echo "${installerUki}:/EFI/boot/boot${pkgs.stdenv.hostPlatform.efiArch}.efi" >>$bootfiles
            '';
            "bootLoaderSpec" =
              ''
                echo ${installerBlsEntry}:/loader/entries/installer.conf >>$bootfiles
                echo ${installerSystem.config.system.build.kernel}/${installerSystem.config.system.boot.loader.kernelFile}:/linux >>$bootfiles
                echo ${installerInitialRamdisk}/${installerSystem.config.system.boot.loader.initrdFile}:/initrd >>$bootfiles
              ''
              + lib.optionalString config.hardware.deviceTree.enable ''
                echo "${installerSystem.config.hardware.deviceTree.package}/${installerSystem.config.hardware.deviceTree.name}:/devicetree.dtb" >>$bootfiles
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
