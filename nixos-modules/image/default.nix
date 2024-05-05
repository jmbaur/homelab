{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.image;

  inherit (config.system.image) version;

  maxUsrSize = cfg.immutableMaxSize;
  maxUsrHashSize = maxUsrSize / 8;

  wantLuksRoot = if cfg.encrypt then (if cfg.hasTpm2 then "tpm2" else "key-file") else "none";
in
{
  imports = [
    ./boot
    ./installer
    ./updates
  ];

  options.custom.image = with lib; {
    enable = mkEnableOption "TODO";

    hasTpm2 = mkEnableOption "TODO";

    encrypt = mkEnableOption "TODO" // {
      default = true;
    };

    mutableNixStore = mkEnableOption "TODO";

    sectorSize = mkOption {
      type =
        with types;
        enum [
          512
          1024
          2048
          4096
        ];
      default = 512;
      example = literalExpression "4096";
      description = ''
        The sector size of the disk image produced by systemd-repart. This
        value must be a power of 2 between 512 and 4096.
      '';
    };

    postImageCommands = mkOption {
      type = types.lines;
      default = "";
      description = ''
        TODO
      '';
    };

    bootFileCommands = mkOption {
      type = types.lines;
      default = "";
      description = ''
        TODO
      '';
    };

    immutableMaxSize = mkOption {
      type = types.int;
      default = 2 * 1024 * 1024 * 1024; # 2G
      example = literalExpression "2 * 1024 * 1024 * 1024 /* 2G */";
      description = ''
        Maximum size for immutable partitions.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion =
              config.system.image.version != null && lib.versionAtLeast config.system.image.version "0.0.1";
            message = "Image version must be set and must be at least 0.0.1";
          }
          {
            assertion = config.system.image.id != null;
            message = "Image ID must be set";
          }
        ];

        systemd.additionalUpstreamSystemUnits = [ "boot-complete.target" ];

        boot.loader.external.enable = true;
        boot.loader.external.installHook = lib.getExe' pkgs.coreutils "true"; # do nothing

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
          "mount.usr=/dev/mapper/usr"
          "mount.usrflags=ro"
          "mount.usrfstype=erofs"
          "systemd.verity_root_options=panic-on-corruption"
        ];

        # We do this because we need the udev rules and some binaries from the lvm2
        # package.
        boot.initrd.services.lvm.enable = true;

        # We have our own /usr/bin/env from the read-only partition
        #
        # See https://github.com/NixOS/nixpkgs/pull/309336
        environment.usrbinenv = null;
        system.activationScripts.usrbinenv = lib.mkForce "";

        boot.initrd = {
          systemd = {
            enable = true;
            enableTpm2 = cfg.hasTpm2;
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
                  before = [
                    "initrd-fs.target"
                    "umount.target"
                  ];
                  unitConfig = {
                    DefaultDependencies = false;
                    RequiresMountsFor = "/sysroot/usr";
                  };
                }
                (
                  # TODO(jared): Use local-overlay-store feature in
                  # https://github.com/NixOS/nix/pull/8397 for implementation
                  # of this.
                  if cfg.mutableNixStore then
                    {
                      what = "overlay";
                      type = "overlay";
                      options = lib.concatStringsSep "," [
                        "lowerdir=/sysroot/usr/store"
                        "upperdir=/sysroot/nix/.rw-store/store"
                        "workdir=/sysroot/nix/.rw-store/work"
                      ];
                    }
                  else
                    {
                      what = "/sysroot/usr/store";
                      type = "none";
                      options = "bind";
                    }
                )
              )
            ];

            # This needs to be set in order to create the root partition
            # dynamically on first boot. Systemd will take this path and find
            # the backing block device. Since the veritysetup generator runs
            # early in the initrd, this path will exist before systemd-repart
            # runs. See https://github.com/systemd/systemd/blob/6bd675a659a508cd1df987f90b633ed1c4b12cb3/src/partition/repart.c#L7705.
            repart.device = "/dev/mapper/usr";
          };

          availableKernelModules = [ "dm_verity" ] ++ lib.optional cfg.mutableNixStore "overlay";
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
            Label = "usr-${version}";
            SizeMinBytes = toString maxUsrSize;
            SizeMaxBytes = toString maxUsrSize;
          };
          "20-usr-hash-a" = {
            Type = "usr-verity";
            Label = "usr-hash-${version}";
            SizeMinBytes = toString maxUsrHashSize;
            SizeMaxBytes = toString maxUsrHashSize;
          };

          # The "B" update partition and root partition get created on first boot.
          "30-usr-b" = {
            Type = "usr";
            Label = "usr-0.0.0";
            SizeMinBytes = toString maxUsrSize;
            SizeMaxBytes = toString maxUsrSize;
          };
          "30-usr-hash-b" = {
            Type = "usr-verity";
            Label = "usr-hash-0.0.0";
            SizeMinBytes = toString maxUsrHashSize;
            SizeMaxBytes = toString maxUsrHashSize;
          };
          "40-root" = {
            Type = "root";
            Label = "root";
            Format = "btrfs";
            FactoryReset = true;
            MakeDirectories = lib.mkIf cfg.mutableNixStore (toString [
              "/nix/.rw-store/store"
              "/nix/.rw-store/work"
            ]);
            Encrypt = wantLuksRoot;
            Weight = 1000;
          };
        };

        boot.initrd.luks.devices.root = lib.mkIf cfg.encrypt {
          device = "/dev/disk/by-partlabel/${config.systemd.repart.partitions."40-root".Label}";
          crypttabExtraOpts = lib.optional cfg.hasTpm2 "tpm2-device=auto";
          tryEmptyPassphrase = !cfg.hasTpm2;
        };

        # enable zram by default since we don't create any swap partitions
        zramSwap.enable = lib.mkDefault true;

        boot.initrd.supportedFilesystems = [ "erofs" ];

        fileSystems."/" = {
          fsType = config.systemd.repart.partitions."40-root".Format;
          options = [
            "compress=zstd"
            "noatime"
            "defaults"
          ];
          device =
            if cfg.encrypt then
              "/dev/mapper/root"
            else
              "/dev/disk/by-partlabel/${config.systemd.repart.partitions."40-root".Label}";
        };
        fileSystems.${config.boot.loader.efi.efiSysMountPoint} = {
          device = "/dev/disk/by-partlabel/${config.systemd.repart.partitions."10-boot".Label}";
          fsType = config.systemd.repart.partitions."10-boot".Format;
          options = [ "x-systemd.automount" ];
        };

        systemd.services.initialize-nix-database = lib.mkIf config.nix.enable {
          unitConfig.ConditionPathExists = [ "/usr/.nix-path-registration" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          path = [ config.nix.package ];
          script = "nix-store --load-db </usr/.nix-path-registration";
          wantedBy = [ "multi-user.target" ];
        };

        system.build.image = pkgs.callPackage ./image.nix {
          toplevelClosure = pkgs.closureInfo {
            rootPaths = [
              config.system.build.toplevel
              pkgs.coreutils
            ];
          };
          usrFormat = "erofs";
          imageName = config.networking.hostName;
          inherit (cfg) bootFileCommands postImageCommands sectorSize;
          inherit (config.system.image) id version;
          inherit (config.systemd.repart) partitions;
        };
      }
      ({
        # moving closer to perlless system
        programs.less.lessopen = lib.mkDefault null;
        programs.command-not-found.enable = lib.mkDefault false;
        boot.enableContainers = lib.mkDefault false;
        environment.defaultPackages = lib.mkDefault [ ];
        documentation.info.enable = lib.mkDefault false;
      })
    ]
  );
}
