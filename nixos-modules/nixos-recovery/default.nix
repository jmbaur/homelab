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
    mkDefault
    mkEnableOption
    mkForce
    mkIf
    mkOption
    types
    ;

  cfg = config.custom.recovery;

  baseConfig = config;
  fstab = baseConfig.environment.etc.fstab.source;
  updateEndpoint = baseConfig.custom.update.endpoint;

  nixosRecovery = pkgs.nixos-recovery.override {
    nix = config.nix.package;
    nixos-install = config.system.build.nixos-install;
    systemd = config.systemd.package;
  };

  # TODO(jared): This should be an option that can be extended on a per-machine
  # basis, as it's hard to predict ahead of time how much custom
  # hardware-related configuration is needed to get the machine to boot.
  inheritFromBaseConfig = {
    _file = "<homelab/nixos-modules/recovery/default.nix#inheritFromBaseConfig>";

    system.stateVersion = config.system.stateVersion;

    # Inherit the finalized package-set from the parent config,
    # prevents a re-import of nixpkgs. Since we already have
    # a finalized package-set, prevent a re-import by removing all
    # overlays in the extended config. The downside to this is that
    # we remove the ability to apply overlays only for the recovery
    # system, though we shouldn't need to do that.
    nixpkgs.pkgs = pkgs;
    nixpkgs.overlays = mkForce [ ];

    networking.hostName = "${config.networking.hostName}-recovery";

    networking.wireless.iwd = config.networking.wireless.iwd;

    # Reuse the substituters and trusted public keys from the parent config so
    # that nixos-install works.
    nix.package = config.nix.package;
    nix.settings = mkForce config.nix.settings;

    # An apply function on this option means that we end up having this strange
    # looking way of inheriting what is set in the parent configuration.
    hardware.firmware = flatten options.hardware.firmware.definitions;

    hardware.deviceTree = removeAttrs config.hardware.deviceTree [ "base" ];

    # NOTE: We don't inherit config.boot.kernelPatches because we already
    # get them by inheriting config.boot.kernelPackages (see https://github.com/nixos/nixpkgs/blob/80ddc2ca0a4ee96b330bffb4d8ec4dbf9bd16fe8/nixos/modules/system/boot/kernel.nix#L46).
    boot.kernelParams = config.boot.kernelParams;
    boot.kernelPackages = config.boot.kernelPackages;
    boot.kernelPatches = mkForce [ ];
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

      # The recovery system is not persistent, no need to enable
      # switch-to-configuration.
      system.switch.enable = false;

      # We don't do bootloader installs for the recovery system.
      boot.loader.grub.enable = false;

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
          "10-boot" = mkIf baseConfig.boot.loader.systemd-boot.enable {
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

      custom.basicNetwork.enable = true;

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
            "--update-endpoint=${updateEndpoint}"
            "--target-disk=${cfg.targetDisk}"
            "--fstab=${fstab}"
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

    boot.loader.systemd-boot.enable = mkDefault true;

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
    zramSwap.enable = mkDefault true;

    # Not applicable for our image-based systems since the root filesystem
    # isn't created at build-time.
    systemd.services.systemd-growfs-root.enable = false;

    system.build = {
      inherit recovery;

      # Add hydra-build-products so that the recovery images can be downloaded
      # from the web UI.
      recoveryImage = recovery.config.system.build.image.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            mkdir -p $out/nix-support
            echo "file recovery-image $out/recovery.raw.zst" >> $out/nix-support/hydra-build-products
          '';
      });
    };
  };
}
