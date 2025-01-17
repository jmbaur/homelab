{
  options,
  config,
  lib,
  noUserModules,
  pkgs,
  ...
}:

let
  inherit (lib)
    flatten
    getExe
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.custom.recovery;
  fstab = config.environment.etc.fstab.source;
  updateEndpoint = config.custom.update.endpoint;

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

    # An apply function on this option means that we end up having this strange
    # looking way of inheriting what is set in the parent configuration.
    hardware.firmware = flatten options.hardware.firmware.definitions;

    hardware.deviceTree = removeAttrs config.hardware.deviceTree [ "base" ];

    boot.kernelParams = config.boot.kernelParams;
    # boot.kernelPatches = config.boot.kernelPatches; # TODO(jared): causes rebuilds
    boot.kernelPackages = config.boot.kernelPackages;
    boot.kernelModules = config.boot.kernelModules;
    boot.initrd.kernelModules = config.boot.initrd.kernelModules;
    boot.initrd.availableKernelModules = config.boot.initrd.availableKernelModules;
    boot.initrd.extraFirmwarePaths = config.boot.initrd.extraFirmwarePaths;
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
              Label = "recovery-boot";
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
              Label = "recovery-root";
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

      fileSystems."/nix/.ro-store" = {
        fsType = "squashfs";
        device = "/dev/disk/by-partlabel/recovery-root";
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

      # Allow "rescue.target" to work
      users.users.root.hashedPasswordFile = "${pkgs.writeText "hashed-password.root" ""}";
      users.mutableUsers = false;

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
        onSuccess = [ "reboot.target" ];
        onFailure = [ "rescue.target" ];
        serviceConfig = {
          StandardError = "tty";
          StandardInput = "tty";
          StandardOutput = "tty";
          ExecStart = toString [
            (getExe nixosRecovery)
            updateEndpoint
            cfg.targetDisk
            fstab
          ];
        };
      };
    };

  recovery = (
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
    assertions = [
      {
        assertion = config.custom.update.enable;
        message = "nixos-recovery (`config.custom.recovery`) does not work without also enabling nixos-update (`config.custom.update`)";
      }
    ];

    boot.loader.systemd-boot.enable = true;

    fileSystems.${config.boot.loader.efi.efiSysMountPoint} = {
      device = "/dev/disk/by-partlabel/boot";
      fsType = "vfat";
      options = [
        "x-systemd.automount"
        "umask=0077"
      ];
    };

    fileSystems."/" = {
      fsType = "btrfs";
      device = "/dev/mapper/root";
      options = [
        "compress=zstd"
        "defaults"
        "noatime"
        "subvol=/root"
      ];
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

    system.build = { inherit recovery; };
  };
}
