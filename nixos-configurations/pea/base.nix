{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  sectorSize = 512;
  splSector = 256;
  splOffsetKiB = sectorSize * splSector / 1024;

  uboot = pkgs.uboot-bananapi_m2_zero.override {
    extraStructuredConfig = with lib.kernel; {
      DISTRO_DEFAULTS = unset;
      BOOTSTD_DEFAULTS = yes;
      FIT = yes;

      # Allow for using u-boot scripts.
      BOOTSTD_FULL = yes;

      # Allow for larger than the default 8MiB kernel size
      SYS_BOOTM_LEN = freeform "0x${lib.toHexString (12 * 1024 * 1024)}"; # 12MiB

      BOOTCOUNT_LIMIT = yes;
      BOOTCOUNT_ENV = yes;
    };
  };
in
{
  disabledModules = [
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/profiles/all-hardware.nix"
  ];

  custom.server.enable = true;
  custom.image = {
    installer.targetDisk = "/dev/mmcblk0";
    postImageCommands = ''
      dd status=none if=${config.system.build.firmware}/u-boot-sunxi-with-spl.bin of=$out/image.raw bs=1K seek=${toString splOffsetKiB} conv=notrunc,sync
    '';
    boot.uefi.enable = true;
  };

  # TPM kernel modules aren't built in our defconfig
  boot.initrd.systemd.tpm2.enable = false;

  # Not using UEFI here
  systemd.package = pkgs.systemd.override { withEfi = false; };

  system.build.firmware = uboot;

  nixpkgs.hostPlatform = {
    config = "armv7l-unknown-linux-gnueabihf";
    gcc = {
      arch = "armv7-a";
      fpu = "vfpv3-d16";
    };
    linux-kernel = {
      DTB = true;
      target = "zImage";
      name = "sunxi";
      baseConfig = "sunxi_defconfig";
      autoModules = true;
      preferBuiltin = true;
    };
  };

  hardware.deviceTree.enable = true;
  hardware.deviceTree.filter = "sun8i-h2-plus-bananapi-m2-zero.dtb";

  boot.initrd.includeDefaultModules = false;

  environment.etc."fw_env.config".text = ''
    ${config.boot.loader.efi.efiSysMountPoint}/uboot.env 0x0000 0x10000
  '';

  environment.systemPackages = [ pkgs.uboot-env-tools ];
}
