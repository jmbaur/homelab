{ config, lib, pkgs, modulesPath, ... }:
let
  sectorSize = 512;
  splSector = 256;
  splOffsetKiB = sectorSize * splSector / 1024;

  # DRAM starts at 0x4000_0000
  # Default $loadaddr is 0x4200_0000
  # https://wiki.friendlyelec.com/wiki/images/0/08/Allwinner_H2+_Datasheet_V1.2.pdf
  loadAddr = "0x42000000";
  kernelAddrR = "0x44000000";
  fdtAddrR = "0x45000000";
  ramdiskAddrR = "0x45400000";

  uboot = pkgs.uboot-bananapi_m2_zero.override {
    debug = true;
    extraStructuredConfig = with pkgs.ubootLib; {
      # Allow for using u-boot scripts.
      BOOTSTD_FULL = yes;

      # Allow for larger than the default 8MiB kernel size
      SYS_BOOTM_LEN = freeform "0x${lib.toHexString (12 * 1024 * 1024)}"; # 12MiB

      # Default load address
      SYS_LOAD_ADDR = freeform loadAddr;

      BOOTCOUNT_LIMIT = yes;
      BOOTCOUNT_ENV = yes;

      # TODO(jared): probably don't need this
      USE_DEFAULT_ENV_FILE = yes;
      DEFAULT_ENV_FILE = freeform (pkgs.substituteAll {
        name = "u-boot.env";
        src = ./u-boot.env.in;
        inherit loadAddr kernelAddrR fdtAddrR ramdiskAddrR;
      });
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
      kernelLoadAddress = kernelAddrR;
    };
  };

  boot.initrd.systemd.enableTpm2 = false; # tpm kernel modules aren't built in our defconfig

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

  # limit the number of tools needing to be built
  system.disableInstallerTools = true;
}
