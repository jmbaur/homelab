{ lib, pkgs, ... }:
let
  uboot = pkgs.uboot-rpi_4.override {
    extraStructuredConfig = with pkgs.ubootLib; {
      # Not enabled by default for RPI 4
      FIT = yes;

      # Allow for using u-boot scripts.
      BOOTSTD_FULL = yes;

      BOOTCOUNT_LIMIT = yes;
      BOOTCOUNT_ENV = yes;
    };
  };
in
{
  nixpkgs.hostPlatform = "aarch64-linux";

  custom.image = {
    enable = true;
    primaryDisk = "/dev/mmcblk0";
    bootFileCommands = ''
      echo "${uboot}/u-boot.bin:kernel8.img" >> $bootfiles
    '';
    uboot = {
      enable = true;
      bootMedium.type = "mmc";
      kernelLoadAddress = "0x3000000";
    };
  };

  hardware.deviceTree.enable = true;
  hardware.deviceTree.filter = "bcm2711-rpi-4-b.dtb";

  boot.kernelParams = [ "console=ttyAMA0" ];

  # {{{ TODO(jared): delete this
  users.allowNoPasswordLogin = true;
  users.users.root.password = lib.warn "EMPTY ROOT PASSWORD, DO NOT USE IN 'PRODUCTION'" "";
  # }}}
}
