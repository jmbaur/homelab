{ pkgs, ... }:
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
  custom.crossCompile.enable = true;
  nixpkgs.hostPlatform = "aarch64-linux";

  custom.fitImage.loadAddress = "0x80000";

  custom.image.enable = true;
  custom.image.bootVariant = "fit-image";
  custom.image.ubootBootMedium.type = "mmc";
  custom.image.bootFileCommands = ''
    echo "${uboot}/u-boot.bin:kernel.img"
  '';

  hardware.deviceTree.enable = true;
  hardware.deviceTree.filter = "bcm2711-rpi-4-b.dtb";

  boot.kernelParams = [ "console=ttyAMA0" ];

  # TODO(jared): delete this
  users.allowNoPasswordLogin = true;
  users.users.root.password = "";
}
