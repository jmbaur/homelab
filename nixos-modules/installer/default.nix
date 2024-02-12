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

    mkdir -p /proc /sys /dev/pts /run
    mount -t proc proc /proc
    mount -t sysfs sysfs /sys
    mount -t devtmpfs devtmpfs /dev
    # TODO(jared): not working: mount -t devpts devpts /dev/pts
    mount -t tmpfs tmpfs /run
  '';
in
{
  system.build.installerInitialRamdisk = pkgs.makeInitrdNG {
    name = "installer-initrd-${kernel-name}";
    inherit (config.boot.initrd) compressor compressorArgs prepend;
    strip = true;

    contents = [
      { object = "${modulesClosure}/lib"; symlink = "/lib"; }
      { object = "${pkgs.busybox}/bin/busybox"; symlink = "/init"; }
      { object = "${pkgs.busybox}/bin"; symlink = "/bin"; }
      { object = "${pkgs.busybox}/sbin"; symlink = "/sbin"; }
      { object = startupScript; symlink = "/etc/init.d/rcS"; }
    ];
  };
}
