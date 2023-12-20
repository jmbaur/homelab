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
      SYS_BOOTM_LEN = freeform "0x${lib.toHexString (12 * 1024 * 1024)}";
    };
  };

  loadAddr = "0x42000000";
  kernelAddrR = "0x44000000";
  fdtAddrR = "0x45000000";
  ramdiskAddrR = "0x45400000";

  # DRAM starts at 0x4000_0000
  # Default $loadaddr is 0x4200_0000
  # https://wiki.friendlyelec.com/wiki/images/0/08/Allwinner_H2+_Datasheet_V1.2.pdf
  #
  # TODO(jared): make this generic across nixos A/B partitions
  bootScript = pkgs.writeText "boot.cmd" ''
    setenv loadaddr       ${loadAddr};
    setenv kernel_addr_r  ${kernelAddrR}
    setenv fdt_addr_r     ${fdtAddrR}
    setenv ramdisk_addr_r ${ramdiskAddrR}
    setenv bootargs       "nixos.nix_store=nixos-a"
    load mmc 0:1 $loadaddr uImage.a
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
      Format = "erofs";
      SizeMinBytes = "3G";
      SizeMaxBytes = "3G";
      SplitName = "-";
    };
  };

  linkNixStore = pkgs.callPackage ./link-nix-store.nix { };
in
{
  disabledModules = [
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/profiles/all-hardware.nix"
  ];

  imports = [
    # TODO(jared): import this, causes a bunch of rebuilds for some reason
    # "${modulesPath}/profiles/image-based-appliance.nix"
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
          Label = "boot";
          SizeMinBytes = "64M";
          SizeMaxBytes = "64M";
          SplitName = "boot";
        };
      };
      "nixos-a" = lib.recursiveUpdate (repartNixos "a") { repartConfig.SplitName = "nixos"; };
      # "nixos-b" = repartNixos "b";
      "state".repartConfig = {
        Type = "linux-generic";
        Format = "ext4";
        Label = "state";
        SplitName = "-";
        MakeDirectories = "/var";
      };
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

  # https://www.freedesktop.org/software/systemd/man/latest/bootup.html#Bootup%20in%20the%20initrd
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.enableTpm2 = false; # tpm kernel modules aren't built in our defconfig
  boot.initrd.systemd.emergencyAccess = true; # TODO(jared): set to false
  boot.initrd.systemd.storePaths = [ linkNixStore ];
  boot.initrd.systemd.services.link-nix-store = {
    unitConfig.DefaultDependencies = false;
    # Only run this after systemd-udevd has settled, so we will have
    # /dev/disk/* symlinks.
    after = [ "systemd-udev-settle.service" ];
    wantedBy = [ "initrd-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = lib.getExe linkNixStore;
    };
  };
  boot.initrd.systemd.mounts = [{
    where = "/sysroot/nix/store";
    what = "/dev/nixos";
    type = config.image.repart.partitions.nixos-a.repartConfig.Format;
    wantedBy = [ "initrd-fs.target" ];
    before = [ "initrd-fs.target" ];
    requires = [ "link-nix-store.service" ];
    after = [ "link-nix-store.service" ];
  }];

  boot.loader.grub.enable = false;
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "mode=755" ];
  };
  fileSystems."/state" = {
    device = "/dev/disk/by-partlabel/${config.image.repart.partitions.state.repartConfig.Label}";
    fsType = config.image.repart.partitions.state.repartConfig.Format;
    neededForBoot = true;
    autoResize = true;
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
