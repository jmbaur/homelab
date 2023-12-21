{ config, lib, pkgs, modulesPath, ... }:
let
  sectorSize = 512;
  splSector = 256;
  splOffsetKiB = sectorSize * splSector / 1024;

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

      USE_DEFAULT_ENV_FILE = yes;
      DEFAULT_ENV_FILE = freeform (pkgs.substituteAll {
        name = "u-boot.env";
        src = ./u-boot.env.in;
        inherit loadAddr kernelAddrR fdtAddrR ramdiskAddrR;
      });
    };
  };

  # DRAM starts at 0x4000_0000
  # Default $loadaddr is 0x4200_0000
  # https://wiki.friendlyelec.com/wiki/images/0/08/Allwinner_H2+_Datasheet_V1.2.pdf
  bootScript = pkgs.writeText "boot.cmd" ''
    if test -z $active; then
      setenv active a;
      saveenv
      echo no active partition set, using partition A
    fi

    setenv bootargs nixos.active=nixos-$active
    load mmc 0:1 $loadaddr uImage.$active
    source ''${loadaddr}:bootscript
  '';

  bootScriptImage = pkgs.runCommand "boot.scr" { } ''
    ${lib.getExe' pkgs.buildPackages.ubootTools "mkimage"} \
      -A ${pkgs.stdenv.hostPlatform.linuxArch} \
      -O linux \
      -T script \
      -C none \
      -d ${bootScript} \
      $out
  '';

  repartNixos = subName: {
    # TODO(jared): We don't need everything from toplevel, like the linux
    # kernel and initrd are unecessary here
    storePaths = [ config.system.build.toplevel ];
    stripNixStorePrefix = true;
    repartConfig = {
      Type = "linux-generic";
      Label = "nixos-${subName}";
      Format = "ext4";
      SizeMinBytes = "3G";
      SizeMaxBytes = "3G";
      SplitName = "-";
    };
  };

  testActiveNixStorePartition = pkgs.writeScript "test-active-nix-store-partition" ''
    #!/bin/bash
    [[ "$1" == "$2" ]] && echo -n active || echo -n inactive
  '';
in

{
  disabledModules = [
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/profiles/all-hardware.nix"
  ];

  imports = [
    "${modulesPath}/profiles/image-based-appliance.nix"
    "${modulesPath}/image/repart.nix"
  ];

  custom.fitImage.loadAddress = kernelAddrR;

  image.repart = {
    name = "image";
    split = true;
    partitions = {
      "boot" = {
        contents = {
          "/boot.scr".source = bootScriptImage;
          "/uImage.a".source = config.system.build.fitImage;
          "/uImage.b".source = config.system.build.fitImage;
        };
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          Label = "BOOT";
          SizeMinBytes = "64M";
          SizeMaxBytes = "64M";
          SplitName = "boot";
        };
      };
      "nixos-a" = lib.recursiveUpdate (repartNixos "a") { repartConfig.SplitName = "nixos"; };
      "nixos-b" = repartNixos "b";
    };
  };

  boot.kernelPatches = [{
    name = "more-filesystem-support";
    patch = null;
    extraStructuredConfig = with lib.kernel; {
      EROFS_FS = yes; # for read-only nix-store partition
      AUTOFS_FS = yes; # systemd-based initrd needs this
    };
  }];

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.enableTpm2 = false; # tpm kernel modules aren't built in our defconfig
  boot.initrd.systemd.emergencyAccess = false;

  # There's gotta be a way to test simple equality in native udev, not shell
  # out to bash or something...
  boot.initrd.systemd.storePaths = [ testActiveNixStorePartition ];
  boot.initrd.services.udev.rules = ''
    SUBSYSTEM!="block", GOTO="active_nixos_partition_end"
    ENV{ID_PART_ENTRY_NAME}=="nixos-[ab]", IMPORT{cmdline}="nixos.active"
    ENV{ID_PART_ENTRY_NAME}=="nixos-[ab]", PROGRAM="${testActiveNixStorePartition} $env{ID_PART_ENTRY_NAME} $env{nixos.active}", SYMLINK+="disk/nixos/%c", TAG="systemd"
    LABEL="active_nixos_partition_end"
  '';

  # https://www.freedesktop.org/software/systemd/man/latest/bootup.html#Bootup%20in%20the%20initrd
  boot.initrd.systemd.mounts = [{
    where = "/sysroot/nix/store";
    what = "/dev/disk/nixos/active";
    type = config.image.repart.partitions."nixos-a".repartConfig.Format;
    options = "ro";
    wantedBy = [ "initrd-fs.target" ];
    before = [ "initrd-fs.target" ];
  }];

  boot.initrd.systemd.repart.enable = true;
  boot.initrd.systemd.repart.device = "/dev/disk/by-path/platform-1c0f000.mmc";
  systemd.repart.partitions = {
    "10-state" = {
      Type = "var";
      Label = "state";
      Format = "ext4";
    };
  };

  boot.loader.grub.enable = false;
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "mode=755" ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/${config.image.repart.partitions."boot".repartConfig.Label}";
    fsType = config.image.repart.partitions."boot".repartConfig.Format;
    options = [ "x-systemd.automount" ];
  };
  fileSystems."/state" = {
    device = "/dev/disk/by-partlabel/${config.systemd.repart.partitions."10-state".Label}";
    fsType = config.systemd.repart.partitions."10-state".Format;
    neededForBoot = true;
  };
  fileSystems."/var" = {
    device = "/state/var";
    options = [ "bind" ];
  };

  system.build.firmware = uboot;
  system.build.imageWithBootloader = pkgs.runCommand "image-with-bootloader" { } ''
    dd if=${config.system.build.image}/image.raw of=$out
    dd if=${config.system.build.firmware}/u-boot-sunxi-with-spl.bin of=$out bs=1K seek=${toString splOffsetKiB} conv=notrunc,sync
  '';

  nixpkgs.hostPlatform = lib.recursiveUpdate lib.systems.platforms.armv7l-hf-multiplatform
    (lib.systems.examples.armv7l-hf-multiplatform // {
      linux-kernel = {
        name = "sunxi";
        baseConfig = "sunxi_defconfig";
        autoModules = false;
        preferBuiltin = true;
      };
    });

  custom.crossCompile.enable = true;

  # TODO(jared): delete this
  users.allowNoPasswordLogin = true;

  hardware.deviceTree.enable = true;
  hardware.deviceTree.filter = "sun8i-h2-plus-bananapi-m2-zero.dtb";

  # limit rebuilding to a minimum
  boot.supportedFilesystems = lib.mkForce [ "ext4" "erofs" ];
  boot.initrd.supportedFilesystems = lib.mkForce [ "ext4" "erofs" ];
  boot.initrd.includeDefaultModules = false;

  # limit the number of tools needing to be built
  system.disableInstallerTools = true;
}
