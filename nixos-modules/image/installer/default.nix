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

  installerCfg = config.custom.image.installer;

  # Make the installer work with lots of common hardware.
  installerSystem = extendModules { modules = [ "${modulesPath}/profiles/all-hardware.nix" ]; };

  kernel-name = installerSystem.config.boot.kernelPackages.kernel.name or "kernel";
  modulesTree = installerSystem.config.system.modulesTree.override {
    name = kernel-name + "-modules";
  };
  firmware = installerSystem.config.hardware.firmware;

  # Determine the set of modules that we need to mount the root FS.
  modulesClosure = pkgs.makeModulesClosure {
    rootModules =
      installerSystem.config.boot.initrd.availableKernelModules
      ++ installerSystem.config.boot.initrd.kernelModules;
    kernel = modulesTree;
    firmware = firmware;
    allowMissing = false;
  };

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

    for i in ${toString config.boot.initrd.kernelModules}; do
      echo "loading module $(basename $i)..."
      modprobe $i
    done

    ln -sfn /proc/self/fd /dev/fd
    ln -sfn /proc/self/fd/0 /dev/stdin
    ln -sfn /proc/self/fd/1 /dev/stdout
    ln -sfn /proc/self/fd/2 /dev/stderr
    mkdir -p /etc/systemd
  '';

  installerKernelParams =
    installerSystem.config.boot.kernelParams
    ++ [
      "installer.target_disk=${cfg.primaryDisk}"
      "installer.source_disk=/dev/disk/by-partlabel/data"
    ]
    ++ lib.optionals installerCfg.rebootOnFailure [ "installer.reboot_on_fail=1" ];

  installerInitialRamdisk = pkgs.makeInitrdNG {
    name = "installer-initrd-${kernel-name}";
    inherit (config.boot.initrd) compressor compressorArgs prepend;
    strip = true;

    contents = [
      {
        object = "${modulesClosure}/lib";
        symlink = "/lib";
      }
      {
        object = "${pkgs.busybox}/bin/busybox";
        symlink = "/init";
      }
      {
        object = "${pkgs.busybox}/bin";
        symlink = "/bin";
      }
      {
        object = "${pkgs.busybox}/sbin";
        symlink = "/sbin";
      }
      {
        object = startupScript;
        symlink = "/etc/init.d/rcS";
      }
      {
        object = pkgs.writers.writeRustBin "installer" { } (builtins.readFile ./installer.rs);
        symlink = "/opt/installer";
      }
      {
        object = pkgs.systemdMinimal;
        symlink = "/opt/systemd";
      }
      {
        object = ./inittab;
        symlink = "/etc/inittab";
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
in
{
  options.custom.image.installer.rebootOnFailure = lib.mkEnableOption "reboot installer on failure";

  config = lib.mkIf cfg.enable {
    # The image to install is kept on an ext4 filesystem. TODO(jared): just
    # write the compressed raw image to the partition directly, no need for a
    # filesystem.
    boot.initrd.supportedFilesystems = [ "ext4" ];

    system.build.networkInstaller = throw "TODO";

    system.build.foo = installerInitialRamdisk;
    system.build.diskInstaller = pkgs.callPackage ./image.nix {
      imageName = config.networking.hostName;
      mainImage = "${config.system.build.image}/image.raw.xz";
      postImageCommands = '''';

      bootFileCommands =
        assert lib.assertMsg cfg.boot.uefi.enable "TODO: installer only works on uefi bootflow as of now";
        ''
          echo "${installerUki}:/EFI/BOOT/BOOT${lib.toUpper pkgs.stdenv.hostPlatform.efiArch}.EFI" >> $bootfiles
        '';

      # TODO(jared): We cannot assume the sector size of the target device is
      # the same as the installation device.
      inherit (cfg) sectorSize;
    };
  };
}
