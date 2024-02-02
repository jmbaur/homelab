{ config, lib, pkgs, modulesPath, ... }:
let
  sectorSize = 512;
  splSector = 256;
  splOffsetKiB = sectorSize * splSector / 1024;

  uboot = pkgs.uboot-bananapi_m2_zero.override {
    extraStructuredConfig = with pkgs.ubootLib; {
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

  custom.image = {
    enable = true;
    primaryDisk = "/dev/mmcblk0";
    postImageCommands = ''
      dd if=${config.system.build.firmware}/u-boot-sunxi-with-spl.bin of=$out/image.raw bs=1K seek=${toString splOffsetKiB} conv=notrunc,sync
    '';
    uboot = {
      enable = true;
      bootMedium.type = "mmc";
      kernelLoadAddress = "0x44000000";
    };
  };

  # tpm kernel modules aren't built in our defconfig
  boot.initrd.systemd.enableTpm2 = false;

  system.build.firmware = uboot;

  nixpkgs.hostPlatform = lib.recursiveUpdate lib.systems.platforms.armv7l-hf-multiplatform
    (lib.systems.examples.armv7l-hf-multiplatform // {
      linux-kernel = {
        name = "sunxi";
        baseConfig = "sunxi_defconfig";
        autoModules = true;
        preferBuiltin = true;
      };
    });

  # {{{ TODO(jared): delete this
  users.allowNoPasswordLogin = true;
  users.users.root.password = lib.warn "EMPTY ROOT PASSWORD, DO NOT USE IN 'PRODUCTION'" "";
  # }}}

  hardware.deviceTree.enable = true;
  hardware.deviceTree.filter = "sun8i-h2-plus-bananapi-m2-zero.dtb";

  boot.initrd.includeDefaultModules = false;

  # for fw_printenv and fw_setenv
  environment.etc."fw_env.config".text = ''
    # VFAT file                                             Device offset   Env. size       Flash sector size       Number of sectors
    ${config.boot.loader.efi.efiSysMountPoint}/uboot.env    0x0000          0x4000
  '';

  environment.systemPackages = with pkgs; [ ubootEnvTools ];
}
