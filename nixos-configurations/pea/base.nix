{ config, lib, pkgs, modulesPath, ... }:
let
  sectorSize = 512;
  splSector = 256;
  splOffsetKiB = sectorSize * splSector / 1024;

  uboot = pkgs.uboot-bananapi_m2_zero.override {
    extraStructuredConfig = with pkgs.ubootLib; {
      # Allow for using u-boot scripts.
      BOOTSTD_FULL = yes;
    };
  };

  bootScript = pkgs.writeText "boot.cmd" ''
    bootflow -lb
  '';

  repartKernel = subName: {
    repartConfig = {
      Type = "linux-generic";
      Label = "kernel-${subName}";
      CopyBlocks = toString config.system.build.fitImage;
      SizeMaxBytes = "64M";
      SplitName = "-";
    };
  };

  repartRoot = subName: {
    storePaths = [ config.system.build.toplevel ];
    repartConfig = {
      Type = "root-${pkgs.stdenv.hostPlatform.linuxArch}";
      Label = "root-${subName}";
      Format = "ext4";
      Minimize = "guess";
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

  custom.fitImage.padToSize = 64 * 1024 * 1024; # 64MiB

  image.repart = {
    name = "image";
    split = true;
    partitions = {
      "boot" = {
        contents."/boot.scr".source = pkgs.runCommand "boot.scr" { } ''
          ${lib.getExe' pkgs.buildPackages.ubootTools "mkimage"} \
            -A ${pkgs.stdenv.hostPlatform.linuxArch} \
            -O linux \
            -T script \
            -C none \
            -d ${bootScript} \
            $out
        '';
        repartConfig = {
          Type = "linux-generic";
          Format = "ext4";
          SizeMinBytes = "4M";
          SplitName = "boot";
        };
      };
      "kernel-a" = lib.recursiveUpdate (repartKernel "a") { repartConfig.SplitName = "kernel"; };
      "kernel-b" = repartKernel "b";
      "root-a" = lib.recursiveUpdate (repartRoot "a") { repartConfig.SplitName = "root"; };
      "root-b" = repartRoot "b";
    };
  };

  boot.loader.grub.enable = false;
  fileSystems."/".device = "/dev/root";

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

  users.allowNoPasswordLogin = true;

  hardware.deviceTree.enable = true;
  hardware.deviceTree.filter = "sun8i-h3-bananapi-m2*.dtb";

  systemd.package = pkgs.systemdMinimal.override {
    withLogind = true;
    withPam = true;
    withTimedated = true;
    withTimesyncd = true;
  };

  # these do not work with pkgs.systemdMinimal
  systemd.coredump.enable = false;
  systemd.oomd.enable = false;

  # limit rebuilding to a minimum
  boot.supportedFilesystems = lib.mkForce [ "ext4" ];
  boot.initrd.includeDefaultModules = false;

  # limit the number of tools needing to be built
  system.disableInstallerTools = true;
  environment.defaultPackages = [ ];

  # TODO(jared): these should probably be fixed in nixpkgs? They all assume
  # `config.systemd.package` is not set to something custom.
  nixpkgs.overlays = [
    (_: prev: {
      util-linux = prev.util-linux.override {
        nlsSupport = false;
        ncursesSupport = false;
        systemdSupport = false;
        translateManpages = false;
      };

      mdadm = prev.mdadm.override {
        udev = config.systemd.package;
      };

      tmux = prev.tmux.override {
        withSystemd = false;
      };

      dhcpcd = prev.dhcpcd.override {
        udev = config.systemd.package;
      };

      procps = prev.procps.override {
        withSystemd = false;
      };
    })
  ];

  services.lvm.enable = false;
}
