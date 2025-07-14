# busybox has the following default inittab:
#
# ::sysinit:/etc/init.d/rcS
# ::askfirst:/bin/sh
# ::ctrlaltdel:/sbin/reboot
# ::shutdown:/sbin/swapoff -a
# ::shutdown:/bin/umount -a -r
# ::restart:/sbin/init
# tty2::askfirst:/bin/sh
# tty3::askfirst:/bin/sh
# tty4::askfirst:/bin/sh

{
  config,
  lib,
  pkgs,
  ...
}:

let
  usrTree = pkgs.buildEnv {
    name = "debug-initrd-usr";
    pathsToLink = [
      "/lib"
      "/bin"
      "/sbin"
    ];
    paths = [
      pkgs.busybox
      pkgs.cryptsetup
      pkgs.kmod
    ] ++ config.system.fsPackages;
  };
in
{
  system.build.debugInitrd = pkgs.makeInitrdNG {
    name = "debug-initrd";

    inherit (config.boot.initrd) compressor compressorArgs prepend;

    contents = [
      {
        target = "/init";
        source = lib.getExe' pkgs.busybox "busybox";
      }
      {
        target = "/etc/init.d/rcS";
        source = pkgs.writeScript "rcS" ''
          #!/bin/sh

          mkdir -p /proc && mount -t proc proc /proc
          mkdir -p /sys && mount -t sysfs sysfs /sys
          mkdir -p /dev && mount -t devtmpfs devtmpfs /dev
          mkdir -p /dev/pts && mount -t devpts devpts /dev/pts
          mkdir -p /run && mount -t tmpfs tmpfs /run
          touch /etc/fstab

          for i in ${toString config.boot.initrd.kernelModules}; do
            echo "loading module $(basename $i)..."
            modprobe $i
          done

          ln -sfn /proc/self/fd /dev/fd
          ln -sfn /proc/self/fd/0 /dev/stdin
          ln -sfn /proc/self/fd/1 /dev/stdout
          ln -sfn /proc/self/fd/2 /dev/stderr
        '';
      }
      {
        target = "/usr";
        source = usrTree;
      }
      {
        target = "/bin";
        source = "${usrTree}/bin";
      }
      {
        target = "/sbin";
        source = "${usrTree}/sbin";
      }
      {
        target = "/lib";
        source =
          pkgs.makeModulesClosure {
            rootModules = config.boot.initrd.availableKernelModules ++ config.boot.initrd.kernelModules;
            kernel = config.system.modulesTree;
            firmware = config.hardware.firmware;
            allowMissing = false;
          }
          + "/lib";
      }
    ];
  };
}
