{ config, lib, pkgs, utils, ... }:

let
  cfg = config.custom.image;

  maxUsrSize = cfg.immutableMaxSize;
  maxUsrHashSize = maxUsrSize / 8;
in
{
  options.custom.image = with lib; {
    enable = mkEnableOption "TODO";

    mutableNixStore = mkEnableOption "TODO";

    bootFileCommands = mkOption {
      type = types.lines;
      default = "";
      description = mdDoc ''
        TODO
      '';
    };

    primaryDisk = mkOption {
      type = types.path;
      description = mdDoc ''
        TODO
      '';
    };

    immutableMaxSize = mkOption {
      type = types.int;
      default = 2 * 1024 * 1024 * 1024; # 2G
      example = literalExpression "2 * 1024 * 1024 * 1024 /* 2G */";
      description = lib.mdDoc ''
        Maximum size for immutable partitions.
      '';
    };

    bootVariant = mkOption {
      type = types.enum [ "uefi" "fit-image" ];
      default = "uefi";
      description = mdDoc ''
        TODO
      '';
    };
  };

  imports = [
    ./boot/fit-image
    ./boot/uefi
  ];

  config = lib.mkIf cfg.enable {
    # we don't need nixpkgs boot-loading infrastructure
    boot.loader.grub.enable = false;

    users.mutableUsers = cfg.mutableNixStore;
    nix.enable = cfg.mutableNixStore;
    system.disableInstallerTools = true;
    system.switch.enable = false;

    boot.kernelParams = [
      "systemd.verity_root_options=panic-on-corruption"

      # Tell systemd to not automount anything on /usr. We don't
      # actually have a /usr mount in our fstab...
      "mount.usr=fstab"
    ];

    # We do this because we need the udev rules and some binaries from the lvm2
    # package.
    boot.initrd.services.lvm.enable = true;

    systemd.package = pkgs.systemd.overrideAttrs (old: {
      patches = old.patches ++ [ ./systemd-repart.patch ];
    });

    boot.initrd = {
      systemd = {
        emergencyAccess = lib.warn "initrd emergency access enabled" true;

        enable = true;
        repart.enable = true;
        additionalUpstreamUnits = [
          "remote-veritysetup.target"
          "veritysetup-pre.target"
          "veritysetup.target"
        ];
        storePaths = [
          "${config.boot.initrd.systemd.package}/lib/systemd/system-generators/systemd-veritysetup-generator"
          "${config.boot.initrd.systemd.package}/lib/systemd/systemd-veritysetup"
        ];

        # Require that systemd-repart only starts after we have our dm-verity
        # device. This prevents a race condition between systemd-repart and
        # systemd-veritysetup.
        services.systemd-repart.after = map (device: "${utils.escapeSystemdPath device}.device") [
          "/dev/mapper/usr"
          "/dev/disk/by-partlabel/usr-a"
        ];
        services.systemd-repart.requires = config.boot.initrd.systemd.services.systemd-repart.after;

        # This needs to be set in order to create the root partition
        # dynamically on first boot.
        repart.device = cfg.primaryDisk;
      };

      availableKernelModules = [ "dm-verity" ] ++ lib.optional cfg.mutableNixStore "overlay";
    };

    # We specify Weight=0 for all partitions that we don't want to grow at all
    # during first boot.
    systemd.repart.partitions = {
      "10-boot" = {
        Type = "esp";
        Label = "BOOT";
        Format = "vfat";
        SizeMinBytes = "256M";
        SizeMaxBytes = "256M";
      };
      "20-usr-a" = {
        Type = "usr";
        Label = "usr-a";
        SizeMinBytes = toString maxUsrSize;
        SizeMaxBytes = toString maxUsrSize;
      };
      "20-usr-a-hash" = {
        Type = "usr-verity";
        Label = "usr-a-hash";
        SizeMinBytes = toString maxUsrHashSize;
        SizeMaxBytes = toString maxUsrHashSize;
      };

      # The "B" update partition and root partition get created on first boot.
      "20-usr-b" = {
        Type = "usr";
        Label = "usr-b";
        SizeMinBytes = toString maxUsrSize;
        SizeMaxBytes = toString maxUsrSize;
      };
      "20-usr-b-hash" = {
        Type = "usr-verity";
        Label = "usr-b-hash";
        SizeMinBytes = toString maxUsrHashSize;
        SizeMaxBytes = toString maxUsrHashSize;
      };
      "30-root" = {
        Type = "root";
        Label = "root";
        Format = "btrfs";
        FactoryReset = true;
        MakeDirectories = lib.mkIf cfg.mutableNixStore (toString [ "/nix/.rw-store/upper" "/nix/.rw-store/work" ]);
      };
    };

    # enable zram by default since we don't create any swap partitions
    zramSwap.enable = lib.mkDefault true;

    fileSystems."/" = {
      device = "/dev/disk/by-partlabel/${config.systemd.repart.partitions."30-root".Label}";
      fsType = config.systemd.repart.partitions."30-root".Format;
      options = [ "compress=zstd" "noatime" "defaults" ];
    };
    fileSystems."/nix/.ro-store" = {
      device = "/dev/mapper/usr";
      fsType = "squashfs"; # TODO(jared): erofs results in dm-verity corruption
      options = [ "ro" ];
      neededForBoot = true;
    };
    fileSystems."/nix/store" =
      if cfg.mutableNixStore then {
        device = "overlay";
        fsType = "overlay";
        options = [ "lowerdir=/sysroot/nix/.ro-store" "upperdir=/sysroot/nix/.rw-store/upper" "workdir=/sysroot/nix/.rw-store/work" ];
      } else {
        device = "/nix/.ro-store";
        fsType = "none";
        options = [ "bind" ];
      };
    fileSystems."/boot" = {
      device = "/dev/disk/by-partlabel/${config.systemd.repart.partitions."10-boot".Label}";
      fsType = config.systemd.repart.partitions."10-boot".Format;
      options = [ "x-systemd.automount" ];
    };

    boot.postBootCommands = lib.optionalString cfg.mutableNixStore ''
      ${lib.getExe' config.nix.package "nix-store"} --load-db </nix/.ro-store/.nix-path-registration
    '';

    system.build.image = pkgs.callPackage ./image.nix {
      usrFormat = config.fileSystems."/nix/.ro-store".fsType;
      imageName = config.networking.hostName;
      inherit (cfg) bootFileCommands;
      inherit (config.system.build) toplevel;
      inherit (config.systemd.repart) partitions;
    };
  };
}
