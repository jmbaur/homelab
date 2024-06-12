{ lib, pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-linux";

  # requires linux 6.8
  hardware.deviceTree.name = "allwinner/sun50i-h618-orangepi-zero3.dtb";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  users.users.root.password = lib.warn "EMPTY ROOT PASSWORD, DO NOT USE IN 'PRODUCTION'" "";

  custom.image = {
    installer.targetDisk = "/dev/disk/by-path/TODO";
    boot.uboot.enable = true;
  };
}
