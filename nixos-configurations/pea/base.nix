{ config, lib, pkgs, modulesPath, ... }:
let
  sectorSize = 512;
  splSector = 256;
  splOffsetKiB = sectorSize * splSector / 1024;

  uboot = pkgs.uboot-bananapi_m2_zero.override {
    extraStructuredConfig = with pkgs.ubootLib; {
      # Allow for using u-boot scripts.
      BOOTSTD_FULL = yes;

      # Change the bootm size limit to 32MiB, we shouldn't need much more than
      # 16MiB though.
      SYS_BOOTM_LEN = freeform "0x${lib.toHexString (32 * 1024 * 1024)}";
    };
  };

  # TODO(jared): make this generic across nixos A/B partitions
  bootScript = pkgs.writeText "boot.cmd" ''
    setenv bootargs "nixos.nix_store=nixos-a"
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
      Format = "ext4"; # "erofs";
      SizeMinBytes = "3G";
      SizeMaxBytes = "3G";
      SplitName = "-";
    };
  };
in
{
  disabledModules = [
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/profiles/all-hardware.nix"
  ];

  imports = [ "${modulesPath}/image/repart.nix" ];

  image.repart = {
    name = "image";
    split = true;
    partitions = {
      "boot" = {
        contents = {
          "/boot.scr".source = bootScriptImage;
          "/uImage.a".source = config.system.build.fitImage;
          # "/uImage.b".source = config.system.build.fitImage;
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
        Format = "ext4"; # TODO(jared): use something like btrfs
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
      EROFS_FS = yes;
    };
  }];

  # TODO(jared): switch to systemd-based initrd
  boot.initrd.systemd.enable = lib.mkForce false;
  boot.initrd.postDeviceCommands = ''
    (
      set -e
      nix_store=$(cat /proc/cmdline | tr ' ' '\n' | grep nixos.nix_store= | cut -d'=' -f2)
      ln -sfv "/dev/disk/by-partlabel/$nix_store" ${config.fileSystems."/nix/store".device}
    )
  '';

  # TODO(jared): use systemd-repart in the initrd to create the state partition
  # boot.initrd.systemd.repart = {
  #   enable = true;
  #   partitions."10-state" = { };
  # };
  boot.initrd.systemd.emergencyAccess = true;

  boot.loader.grub.enable = false;
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "mode=755" ];
  };
  fileSystems."/nix/store" = {
    device = "/dev/nixos";
    fsType = "ext4"; # "erofs";
    options = [ "ro" ];
  };
  fileSystems."/state" = {
    device = "/dev/disk/by-partlabel/${config.image.repart.partitions.state.repartConfig.Label}";
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
  boot.supportedFilesystems = lib.mkForce [ "ext4" ];
  boot.initrd.supportedFilesystems = lib.mkForce [ "ext4" "erofs" ];
  boot.initrd.includeDefaultModules = false;

  # limit the number of tools needing to be built
  system.disableInstallerTools = true;
  environment.defaultPackages = [ ];
}
