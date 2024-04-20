{ config, pkgs, ... }:
let
  kernel-name = config.boot.kernelPackages.kernel.name or "kernel";
  modulesTree = config.system.modulesTree.override { name = kernel-name + "-modules"; };
  firmware = config.hardware.firmware;
  # Determine the set of modules that we need to mount the root FS.
  modulesClosure = pkgs.makeModulesClosure {
    rootModules = config.boot.initrd.availableKernelModules ++ config.boot.initrd.kernelModules;
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
  '';
in
{
  system.build.installerUki = pkgs.callPackage (
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
          --uname=${config.system.build.kernel.version} \
          --stub=${config.systemd.package}/lib/systemd/boot/efi/linux${pkgs.stdenv.hostPlatform.efiArch}.efi.stub \
          --linux=${config.system.build.kernel}/${config.system.boot.loader.kernelFile} \
          --cmdline="${toString config.boot.kernelParams}" \
          --initrd=${config.system.build.installerInitialRamdisk}/${config.system.boot.loader.initrdFile} \
          --os-release=@${config.environment.etc."os-release".source} \
          ${lib.optionalString config.hardware.deviceTree.enable "--devicetree=${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}"} \
          --output=$out
      '';
    }
  ) { };

  system.build.installerInitialRamdisk = pkgs.makeInitrdNG {
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
    ];
  };
}
