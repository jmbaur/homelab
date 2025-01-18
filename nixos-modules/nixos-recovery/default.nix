{
  config,
  lib,
  noUserModules,
  pkgs,
  ...
}:

let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.custom.recovery;
  fstab = config.environment.etc.fstab.source;

  nixosRecovery = pkgs.writeShellApplication {
    name = "nixos-recovery";

    runtimeInputs = [
      "/run/wrappers" # mount
      config.nix.package # nix-env
      config.system.build.nixos-install
      config.systemd.package # systemd-repart
      pkgs.btrfs-progs # mkfs.btrfs
      pkgs.cryptsetup
      pkgs.curl
      pkgs.dosfstools # mkfs.vfat
      pkgs.util-linux # sfdisk
    ];

    text = builtins.readFile ./nixos-recovery.bash;
  };

  # TODO(jared): This should be an option that can be extended on a per-machine
  # basis, as it's hard to predict ahead of time how much custom
  # hardware-related configuration is needed to get the machine to boot.
  inheritFromBaseConfig = {
    _file = "<homelab/nixos-modules/recovery/default.nix#inheritFromBaseConfig>";

    system.stateVersion = config.system.stateVersion;

    # Inherit the finalized package-set from the parent config, prevents
    # a re-import of nixpkgs.
    nixpkgs.pkgs = pkgs;

    networking.hostName = "${config.networking.hostName}-recovery";

    # Reuse the substituters and trusted public keys from the parent config so
    # that nixos-install works.
    nix.settings = {
      substituters = config.nix.settings.substituters or [ ];
      extra-substituters = config.nix.settings.extra-substituters or [ ];
      trusted-public-keys = config.nix.settings.trusted-public-keys or [ ];
      extra-trusted-public-keys = config.nix.settings.extra-trusted-public-keys or [ ];
    };

    boot.kernelPackages = config.boot.kernelPackages;
    boot.kernelModules = config.boot.kernelModules;
    boot.initrd.kernelModules = config.boot.initrd.kernelModules;
    boot.initrd.availableKernelModules = config.boot.initrd.availableKernelModules;
  };

  recoveryConfig =
    {
      config,
      pkgs,
      modulesPath,
      utils,
      ...
    }:

    let
      inherit (pkgs.stdenv.hostPlatform) efiArch;
    in
    {
      _file = "<homelab/nixos-modules/recovery/default.nix#recoveryConfig>";

      imports = [
        "${modulesPath}/profiles/minimal.nix"
        "${modulesPath}/image/repart.nix"
      ];

      system.nixos.variant_id = "recovery";
      system.nixos.variantName = "NixOS Recovery";
      system.image.id = "recovery";

      image.repart = {
        name = "recovery";

        compression.enable = true;

        mkfsOptions = {
          squashfs = [ "-comp zstd" ];
          erofs = [
            "-zlz4hc,12"
            "-T0"
          ];
        };

        partitions = {
          "10-boot" = {
            contents = {
              "/EFI/boot/boot${efiArch}.efi".source =
                "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
              "/EFI/Linux/recovery.efi".source =
                "${config.system.build.uki}/${config.system.boot.loader.ukiFile}";
            };
            repartConfig = {
              Type = "esp";
              Label = "BOOT";
              Format = "vfat";
              SizeMaxBytes = "128M";
              SizeMinBytes = "128M";
            };
          };
          "11-recovery" = {
            storePaths = [ config.system.build.toplevel ];
            stripNixStorePrefix = true;
            repartConfig = {
              Type = "linux-generic";
              Format = "squashfs";
              Label = "recovery";
              Minimize = "best";
            };
          };
        };
      };

      environment.etc."repart.d".source = ./repart.d;

      # We don't do bootloader installs for the recovery system.
      boot.loader.grub.enable = false;

      fileSystems."/" = {
        fsType = "tmpfs";
        device = "tmpfs";
        options = [ "mode=0755" ];
      };

      fileSystems.${config.boot.loader.efi.efiSysMountPoint} = {
        fsType = "vfat";
        device = "/dev/disk/by-partlabel/BOOT";
        options = [ "umask=0077" ];
      };

      fileSystems."/nix/.ro-store" = {
        fsType = "squashfs";
        device = "/dev/disk/by-partlabel/recovery";
        neededForBoot = true;
      };

      fileSystems."/nix/store" = {
        fsType = "overlay";
        device = "overlay";
        overlay = {
          lowerdir = [ "/nix/.ro-store" ];
          upperdir = "/nix/.rw-store/upper";
          workdir = "/nix/.rw-store/work";
        };
      };

      # Not strictly needed, but nice to have.
      boot.initrd.systemd.enable = true;

      # Don't launch any gettys
      systemd.services."getty@".enable = false;
      systemd.services."serial-getty@".enable = false;

      systemd.services.nixos-recovery = {
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "${utils.escapeSystemdPath cfg.targetDisk}.device"
        ];
        wants = [
          "network-online.target"
          "${utils.escapeSystemdPath cfg.targetDisk}.device"
        ];
        serviceConfig = {
          StandardOutput = "tty";
          StandardError = "tty";
          ExecStart = toString [
            (getExe nixosRecovery)
            cfg.updateEndpoint
            cfg.targetDisk
            fstab
          ];
        };
      };
    };

  recoverySystem = (
    noUserModules.extendModules {
      modules = [
        inheritFromBaseConfig
        recoveryConfig
      ] ++ cfg.modules;
    }
  );
in
{
  options.custom.recovery = {
    enable = mkEnableOption "recovery";

    updateEndpoint = mkOption {
      type = types.str;
      description = ''
        The HTTP endpoint to use when pulling updates.
      '';
    };

    targetDisk = mkOption {
      type = types.path;
      description = ''
        The path to the block device that NixOS will be installed on.
      '';
    };

    modules = mkOption {
      type = types.listOf types.deferredModule;
      default = [ ];
      description = ''
        Extra NixOS modules to include in the recovery system configuration.
        Can be useful for adding extra hardware support needed for a particular
        machine.
      '';
    };
  };

  config = mkIf cfg.enable {
    boot.loader.systemd-boot.enable = true;

    fileSystems.${config.boot.loader.efi.efiSysMountPoint} = {
      device = "/dev/disk/by-partlabel/BOOT";
      fsType = "vfat";
      options = [
        "x-systemd.automount"
        "umask=0077"
      ];
    };

    fileSystems."/" = {
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "defaults"
        "noatime"
        "subvol=/root"
      ];
      device = "/dev/mapper/root";
    };

    boot.initrd.luks.devices.root = {
      device = "/dev/disk/by-partlabel/root";
      tryEmptyPassphrase = true;
      allowDiscards = config.services.fstrim.enable;
    };

    # enable zram by default since we don't create any swap partitions
    zramSwap.enable = lib.mkDefault true;

    # Not applicable for our image-based systems since the root filesystem
    # isn't created at build-time.
    systemd.services.systemd-growfs-root.enable = false;

    system.build.recoveryImage = recoverySystem.config.system.build.image;
  };
}
