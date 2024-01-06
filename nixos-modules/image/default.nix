{ config, lib, pkgs, utils, ... }:

let
  cfg = config.custom.image;

  maxUsrSize = cfg.immutableMaxSize;
  maxUsrHashSize = maxUsrSize / 8;

  encrypt = if cfg.encrypt then (if cfg.hasTpm2 then "tpm2" else "key-file") else "none";
in
{
  options.custom.image = with lib; {
    enable = mkEnableOption "TODO";

    version = mkOption {
      type = types.str;
      description = mdDoc ''
        TODO
      '';
    };

    hasTpm2 = mkEnableOption "TODO";

    encrypt = mkEnableOption "TODO" // { default = true; };

    mutableNixStore = mkEnableOption "TODO";

    postImageCommands = mkOption {
      type = types.lines;
      default = "";
      description = mdDoc ''
        TODO
      '';
    };

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
    boot.loader.external.enable = true;
    boot.loader.external.installHook = lib.getExe' pkgs.coreutils "true"; # do nothing

    users.mutableUsers = cfg.mutableNixStore;

    # When we have a mutable nix-store, we can still do
    # switch-to-configuration, it just won't be persistent until the updated
    # image is written to one of the update partitions. This can be useful
    # since it still allows us to have runtime updates of systemd services and
    # other things done through the activation script.
    system.switch.enable = cfg.mutableNixStore;
    system.disableInstallerTools = true;

    # Having nix available on a system with a read-only nix-store is
    # meaningless.
    nix.enable = cfg.mutableNixStore;

    boot.kernelParams = [
      "systemd.verity_root_options=panic-on-corruption"

      # Tell systemd to not automount anything on /usr. We don't
      # actually have a /usr mount in our fstab...
      #
      # TODO(jared): we should be using the SD_GPT_FLAG_NO_AUTO partition flag
      # to indicate that the partition should not be auto-mounted. See
      # https://uapi-group.org/specifications/specs/discoverable_partitions_specification/#partition-attribute-flags
      "mount.usr=fstab"
    ];

    # We do this because we need the udev rules and some binaries from the lvm2
    # package.
    boot.initrd.services.lvm.enable = true;

    # NOTE: only needed if we are going to use CopyBlocks
    # systemd.package = pkgs.systemd.overrideAttrs (old: {
    #   patches = old.patches ++ [ ./systemd-repart.patch ];
    # });

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

        mounts = [
          (lib.recursiveUpdate
            {
              where = "/sysroot/nix/store";
              wantedBy = [ "initrd-fs.target" ];
              conflicts = [ "umount.target" ];
              before = [ "initrd-fs.target" "umount.target" ];
              unitConfig = {
                DefaultDependencies = false;
                RequiresMountsFor = "/sysroot/nix/.ro-store";
              };
            }
            (if cfg.mutableNixStore then {
              what = "overlay";
              type = "overlay";
              options = lib.concatStringsSep "," [
                "lowerdir=/sysroot/nix/.ro-store"
                "upperdir=/sysroot/nix/.rw-store/store"
                "workdir=/sysroot/nix/.rw-store/work"
              ];
            } else {
              what = "/sysroot/nix/.ro-store";
              type = "none";
              options = "bind";
            }))
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

      availableKernelModules = [
        "dm_verity"

        # systemd-repart wants to use loop devices for doing "online" partition
        # creation
        "loop"
      ] ++ lib.optional cfg.mutableNixStore "overlay";
    };

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
        MakeDirectories = lib.mkIf cfg.mutableNixStore (toString [ "/nix/.rw-store/store" "/nix/.rw-store/work" ]);
        Encrypt = encrypt;
      };
    };

    boot.initrd.luks.devices.root = lib.mkIf cfg.encrypt {
      device = "/dev/disk/by-partlabel/${config.systemd.repart.partitions."30-root".Label}";
      crypttabExtraOpts = lib.optional cfg.hasTpm2 "tpm2-device=auto";
      tryEmptyPassphrase = !cfg.hasTpm2;
    };

    # enable zram by default since we don't create any swap partitions
    zramSwap.enable = lib.mkDefault true;

    fileSystems."/" = {
      fsType = config.systemd.repart.partitions."30-root".Format;
      options = [ "compress=zstd" "noatime" "defaults" ];
      device =
        if cfg.encrypt then
          "/dev/mapper/root"
        else
          "/dev/disk/by-partlabel/${config.systemd.repart.partitions."30-root".Label}";
    };
    fileSystems."/nix/.ro-store" = {
      device = "/dev/mapper/usr";
      fsType = "squashfs"; # TODO(jared): erofs results in dm-verity corruption
      options = [ "ro" ];
      neededForBoot = true;
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
      inherit (cfg) bootFileCommands postImageCommands;
      inherit (config.system.build) toplevel;
      inherit (config.systemd.repart) partitions;
    };
  };
}
