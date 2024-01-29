{ lib, ... }: {
  nixpkgs.hostPlatform = "aarch64-linux";

  # requires linux 6.8
  hardware.deviceTree.name = "allwinner/sun50i-h618-orangepi-zero2w.dtb";

  users.users.root.password = lib.warn "EMPTY ROOT PASSWORD, DO NOT USE IN 'PRODUCTION'" "";

  custom.image = {
    enable = true;
    primaryDisk = "/dev/disk/by-path/TODO";
    uboot.enable = true;
  };
}
