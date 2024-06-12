{ lib, pkgs, ... }:
let
  uboot = pkgs.uboot-rpi_4.override {
    extraStructuredConfig = with lib.kernel; {
      # Not enabled by default for RPI 4
      FIT = yes;

      # Allow for using u-boot scripts.
      BOOTSTD_FULL = yes;

      BOOTCOUNT_LIMIT = yes;
      BOOTCOUNT_ENV = yes;
    };
  };
  configTxt = pkgs.writeText "config.txt" ''
    [all]
    arm_64bit=1
    arm_boost=1
    armstub=armstub8-gic.bin
    avoid_warnings=1
    disable_overscan=1
    enable_gic=1
    enable_uart=1
  '';
in
{
  nixpkgs.hostPlatform = "aarch64-linux";

  custom.server.enable = true;
  custom.image = {
    installer.targetDisk = "/dev/mmcblk0";
    bootFileCommands = ''
      echo ${uboot}/u-boot.bin:/kernel8.img >> $bootfiles
      echo ${configTxt}:/config.txt >> $bootfiles
      echo ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin:/armstub8-gic.bin >> $bootfiles
      echo ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb:/bcm2711-rpi-4-b.dtb >> $bootfiles
      find ${pkgs.raspberrypifw}/share/raspberrypi/boot -name "fixup*" \
        -exec sh -c 'echo {}:/$(basename {})' \; >> $bootfiles
      find ${pkgs.raspberrypifw}/share/raspberrypi/boot -name "start*" \
        -exec sh -c 'echo {}:/$(basename {})' \; >> $bootfiles
    '';
    boot.uboot = {
      enable = true;
      bootMedium.type = "mmc";
      kernelLoadAddress = "0x3000000";
    };
  };

  # https://forums.raspberrypi.com/viewtopic.php?t=319435
  systemd.repart.partitions."10-boot".Type = lib.mkForce "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7";

  system.build.firmware = uboot;

  hardware.deviceTree.enable = true;
  hardware.deviceTree.name = "broadcom/bcm2711-rpi-4-b.dtb";

  boot.kernelParams = [ "console=ttyS0,115200" ];

  # {{{ TODO(jared): delete this
  users.users.root.password = lib.warn "EMPTY ROOT PASSWORD, DO NOT USE IN 'PRODUCTION'" "";
  # }}}
}
