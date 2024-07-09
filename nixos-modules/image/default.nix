{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.image;

  inherit (config.system.image) version;

  wantLuksRoot = if cfg.encrypt then (if cfg.hasTpm2 then "tpm2" else "key-file") else "off";

  maxUsrPadding = cfg.wiggleRoom;
  maxUsrHashPadding = maxUsrPadding / 8;
in
{
  imports = [
    ./boot
    ./installer
    ./updates
  ];

  options.custom.image = with lib; {
    enable = mkEnableOption "image-based NixOS";

    hasTpm2 = mkEnableOption "system has a TPM2 device";

    encrypt = mkEnableOption "encrypt the root partition" // {
      default = true;
    };

    mutableNixStore = mkEnableOption "read-write /nix/store";

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
        Commands to run after the image has been created at $out/image.raw.
      '';
    };

    # TODO(jared): This is a leaky-ass abstraction, I need to get rid of it.
    bootFileCommands = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands to run that setup the files that appear on the boot partition
      '';
    };

    wiggleRoom = mkOption {
      type = types.int;
      default = 512 * 1024 * 1024; # 512MiB
      example = literalExpression "512 * 1024 * 1024 /* 512MiB */";
      description = ''
        Amount of wiggle room for future updates.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
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
      {
        # TODO(jared): We can't set the local-overlay-store URI in nix.conf
        # since this setting takes precedence over the NIX_REMOTE environment
        # variable, meaning that users cannot just have things work OOTB by
        # setting that variable. So instead, we set NIX_REMOTE in two places
        # with two different values, the nix-daemon uses the
        # local-overlay-store URI and all clients connect to the daemon.
        assertion = config.nix.settings ? store == false;
        message = "store must not be set in nix.conf";
      }
    ];

    systemd.additionalUpstreamSystemUnits = [ "boot-complete.target" ];

    boot.loader.external = lib.mkForce {
      enable = true;
      installHook = lib.getExe' pkgs.coreutils "true"; # do nothing
    };

    # When we have a mutable nix-store, we can still do
    # switch-to-configuration, it just won't be persistent until the updated
    # image is written to one of the update partitions. This can be useful
    # since it still allows us to have runtime updates of systemd services and
    # other things done through the activation script.
    system.switch.enable = false;
    system.switch.enableNg = cfg.mutableNixStore;
    system.disableInstallerTools = true;

    nix = lib.mkMerge [
      {
        # Having nix available on a system with a read-only nix-store is
        # meaningless.
        enable = cfg.mutableNixStore;
      }
      (lib.mkIf cfg.mutableNixStore {
        settings.experimental-features = [
          "local-overlay-store"
          "read-only-local-store"
        ];
        # Make sure we use the nix-daemon so all store operations are applied
        # properly with the local-overlay
        gc.options = "--option store daemon";
      })
    ];

    # So that users running nix commands are able to connect to the right
    # store.
    environment.variables.NIX_REMOTE = lib.mkIf cfg.mutableNixStore "daemon";

    # Ensure the nix-daemon is configured to connect to the correct store.
    systemd.services.nix-daemon.environment.NIX_REMOTE = lib.mkIf cfg.mutableNixStore "local-overlay://?root=/overlay/merged&lower-store=/usr?read-only=true&upper-layer=/overlay/upper";

    boot.kernelParams = [
      "mount.usr=/dev/mapper/usr"
      "mount.usrflags=ro"
      "mount.usrfstype=squashfs"
      "systemd.verity_root_options=panic-on-corruption"
    ];

    # We have our own /usr/bin/env from the read-only partition
    #
    # See https://github.com/NixOS/nixpkgs/pull/309336
    environment.usrbinenv = null;
    system.activationScripts.usrbinenv = lib.mkForce "";

    boot.initrd = {
      # We do this because we need the udev rules and some binaries from the lvm2
      # package.
      services.lvm.enable = true;

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

        # This needs to be set in order to create the root partition
        # dynamically on first boot. Systemd will take this path and find
        # the backing block device. Since the veritysetup generator runs
        # early in the initrd, this path will exist before systemd-repart
        # runs. See https://github.com/systemd/systemd/blob/6bd675a659a508cd1df987f90b633ed1c4b12cb3/src/partition/repart.c#L7705.
        repart.device = "/dev/mapper/usr";

        # TODO(jared): Delete this when https://github.com/systemd/systemd/commit/468d09c3196a7a4c68b2c3f75b4dd8dcbed8650f is in nixpkgs systemd package.
        #
        # systemd-repart doesn't seem to have a way to copy the size of a
        # partition based on the size of another, so we use a small program to
        # determine the size of A that we need to copy to B.
        services.systemd-repart.serviceConfig.ExecStartPre = toString [
          "/bin/ab-size"
          (toString maxUsrPadding)
          (toString maxUsrHashPadding)
        ];

        extraBin.ab-size = lib.getExe (pkgs.buildSimpleRustPackage "ab-size" ./ab-size.rs);
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
      "10-usr-a" = {
        Type = "usr";
        Label = "usr-${version}";
      };
      "10-usr-hash-a" = {
        Type = "usr-verity";
        Label = "usr-hash-${version}";
      };

      # The "B" update partition and root partition get created on first boot.
      "10-usr-b" = {
        Type = "usr";
        Label = "usr-0.0.0";
      };
      "10-usr-hash-b" = {
        Type = "usr-verity";
        Label = "usr-hash-0.0.0";
      };
      "10-root" = {
        Type = "root";
        Label = "root";
        Format = "btrfs";
        FactoryReset = true;
        MakeDirectories = lib.mkIf cfg.mutableNixStore (toString [
          "/overlay/upper"
          "/overlay/work"
        ]);
        Encrypt = wantLuksRoot;
        Weight = 1000;
      };
    };

    boot.initrd.luks.devices.root = lib.mkIf cfg.encrypt {
      device = "/dev/disk/by-partlabel/${config.systemd.repart.partitions."10-root".Label}";
      crypttabExtraOpts = lib.optional cfg.hasTpm2 "tpm2-device=auto";
      tryEmptyPassphrase = !cfg.hasTpm2;
    };

    # enable zram by default since we don't create any swap partitions
    zramSwap.enable = lib.mkDefault true;

    boot.initrd.supportedFilesystems = [ "squashfs" ];

    fileSystems."/" = {
      fsType = config.systemd.repart.partitions."10-root".Format;
      options = [
        "compress=zstd"
        "noatime"
        "defaults"
      ];
      device =
        if cfg.encrypt then
          "/dev/mapper/root"
        else
          "/dev/disk/by-partlabel/${config.systemd.repart.partitions."10-root".Label}";
    };

    fileSystems.${config.boot.loader.efi.efiSysMountPoint} = {
      device = "/dev/disk/by-partlabel/${config.systemd.repart.partitions."10-boot".Label}";
      fsType = config.systemd.repart.partitions."10-boot".Format;
      options = [
        "x-systemd.automount"
        "umask=0077"
      ];
    };

    fileSystems."/overlay/merged/nix/store" = lib.mkIf cfg.mutableNixStore {
      neededForBoot = true;
      overlay = {
        lowerdir = [ "/usr/nix/store" ];
        upperdir = "/overlay/upper";
        workdir = "/overlay/work";
      };
      # Ensure systemd knows the ordering dependency between this mmount and
      # the mount at /nix/store. This ensures they are unmounted in the correct
      # order as well.
      options = [ "x-systemd.before=nix-store.mount" ];
    };

    fileSystems."/nix/store" = {
      device = if cfg.mutableNixStore then "/overlay/merged/nix/store" else "/usr/nix/store";
      options = [
        "ro"
        "bind"
      ];
    };

    # We handle this ourselves, see above. Disabling this also avoids multiple
    # bind mounts on /nix/store.
    boot.readOnlyNixStore = false;

    system.build.image = pkgs.callPackage ./image.nix {
      rootPaths = [ config.system.build.toplevel ];
      usrFormat = "squashfs";
      imageName = config.networking.hostName;
      inherit maxUsrPadding maxUsrHashPadding;
      inherit (cfg) bootFileCommands postImageCommands sectorSize;
      inherit (config.system.image) id version;
      inherit (config.systemd.repart) partitions;
    };

    # Repart seems to need to be started twice when encrypting. Seems related
    # to https://github.com/systemd/systemd/issues/31142,
    # https://github.com/systemd/systemd/issues/31381, and
    # https://lists.freedesktop.org/archives/systemd-devel/2023-June/049165.html.
    boot.initrd.systemd.emergencyAccess =
      lib.warnIf cfg.encrypt
        "initrd emergency access enabled due to systemd-repart instabilities with filesystem encryption"
        cfg.encrypt;
  };
}
