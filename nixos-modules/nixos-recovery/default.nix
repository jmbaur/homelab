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
    any
    flatten
    getExe
    mkDefault
    mkEnableOption
    mkForce
    mkIf
    mkOption
    optionalString
    types
    ;

  cfg = config.custom.recovery;

  baseConfig = config;
  fstab = baseConfig.environment.etc.fstab.source;

  nixosRecovery = pkgs.nixos-recovery.override {
    nix = config.nix.package;
    inherit (config.system.build) nixos-install;
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

    networking.hostName =
      config.networking.hostName + (optionalString (config.networking.hostName != "") "-") + "recovery";

    # Standalone wpa_supplicant, whether or not NetworkManager owns it in the
    # base system.
    networking.wireless.enable = config.networking.wireless.enable;

    # Reuse the substituters and trusted public keys from the parent config so
    # that nixos-install works.
    nix.settings = mkForce config.nix.settings;

    # An apply function on this option means that we end up having this strange
    # looking way of inheriting what is set in the parent configuration.
    hardware.firmware = flatten options.hardware.firmware.definitions;

    hardware.deviceTree = mkForce (removeAttrs config.hardware.deviceTree [ "base" ]);

    # NOTE: We don't inherit config.boot.kernelPatches because we already
    # get them by inheriting config.boot.kernelPackages (see https://github.com/nixos/nixpkgs/blob/80ddc2ca0a4ee96b330bffb4d8ec4dbf9bd16fe8/nixos/modules/system/boot/kernel.nix#L46).
    boot.extraModulePackages = config.boot.extraModulePackages;
    boot.initrd.availableKernelModules = config.boot.initrd.availableKernelModules;
    boot.initrd.includeDefaultModules = config.boot.initrd.includeDefaultModules;
    boot.initrd.extraFirmwarePaths = config.boot.initrd.extraFirmwarePaths;
    boot.initrd.kernelModules = config.boot.initrd.kernelModules;
    boot.kernelModules = config.boot.kernelModules;
    boot.kernelPackages = config.boot.kernelPackages;
    boot.kernelParams = mkForce config.boot.kernelParams;
    boot.kernelPatches = mkForce [ ];
    services.udev.extraRules = config.services.udev.extraRules;
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
        enable = true;

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
            contents =
              if baseConfig.boot.loader.systemd-boot.enable then
                {
                  "/EFI/boot/boot${efiArch}.efi".source =
                    "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
                  "/EFI/Linux/recovery.efi".source =
                    "${config.system.build.uki}/${config.system.boot.loader.ukiFile}";
                }
              else if baseConfig.boot.loader.tinyboot.enable then
                {
                  "/linux".source = "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}";
                  "/initrd".source = "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";
                  "/loader/entries/recovery.conf".source = pkgs.writeText "recovery.conf" ''
                    title recovery
                    linux /linux
                    initrd /initrd
                    options init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}
                  '';
                }
              else
                throw "non-compatible bootloader";

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
            nixStorePrefix = "/";
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

      # Don't launch any gettys
      systemd.services."getty@".enable = false;
      systemd.services."serial-getty@".enable = false;

      # Allow "rescue.target" to work
      users.users.root.hashedPasswordFile = "${pkgs.writeText "hashed-password.root" ""}";
      users.mutableUsers = false;

      # Allow the initrd emergency shell to work
      boot.initrd.systemd.emergencyAccess = true;

      custom.basicNetwork.enable = true;

      # We don't care which interface gives us network connectivity in the
      # recovery system.
      systemd.network.wait-online.anyInterface = true;

      environment.systemPackages = [ nixosRecovery ];

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
        environment.HOME = "/tmp"; # needed by nixos-install
        serviceConfig = {
          StandardError = "journal+console";
          StandardOutput = "journal+console";
          ExecStart = toString [
            (getExe nixosRecovery)
            "--update-endpoint=${cfg.endpoint}"
            "--target-disk=${cfg.targetDisk}"
            "--fstab=${fstab}"
          ];
        };
      };
    };

  recovery = noUserModules.extendModules {
    modules = [
      inheritFromBaseConfig
      recoveryConfig
      cfg.extraModule
    ];
  };
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

    endpoint = mkOption {
      type = types.str;
      description = ''
        The Hydra HTTP endpoint to use when pulling updates.
      '';
    };

    swap = mkOption {
      type = types.enum [
        "zram"
        "zswap"
      ];
      default = "zram";
      description = ''
        How to provide swap.

        - "zram": compressed swap in RAM only, never touches the disk. Use
          this unless the below applies.
        - "zswap": compressed swap in RAM, with cold pages written back to a
          swapfile sized min(RAM/2, 10% of disk). Use this only with NVMe/SSD
          storage, ample free disk space, and a working set that regularly
          exceeds RAM (e.g. a build machine).

        Avoid "zswap" on eMMC/SD/USB storage (flash wear, small disks).
      '';
    };

    extraModule = mkOption {
      type = types.deferredModule;
      default = { };
      description = ''
        Extra NixOS modules to include in the recovery system configuration.
        Can be useful for adding extra hardware support needed for a particular
        machine.
      '';
    };
  };

  config = mkIf cfg.enable {
    boot.loader.systemd-boot.enable = mkDefault (!config.boot.loader.tinyboot.enable);

    fileSystems.${config.boot.loader.efi.efiSysMountPoint} = {
      device = "/dev/disk/by-partlabel/boot";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
        "x-systemd.automount"
        "x-systemd.idle-timeout=1"
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

    # Not applicable for our image-based systems since the root filesystem
    # isn't created at build-time.
    systemd.services.systemd-growfs-root.enable = false;

    # zram needs no disk space and doesn't write to (often flash-based)
    # storage, making it a reasonable default for most machines.
    zramSwap.enable = mkDefault (cfg.swap == "zram");

    boot.kernelParams = mkIf (cfg.swap == "zswap") [
      "zswap.enabled=1"
      # Proactively write cold pages back to the swapfile
      "zswap.shrinker_enabled=1"
    ];

    # Backing store for zswap. The swapfile lives on the encrypted root
    # filesystem in its own subvolume, since btrfs refuses to snapshot a
    # subvolume containing an active swapfile. The size is left unset so that
    # swapfile-create can pick it based on the size of the disk.
    swapDevices = mkIf (cfg.swap == "zswap") (mkDefault [ { device = "/swap/swapfile"; } ]);

    # Like systemd-repart sizing, this is only decided once, when the swapfile
    # doesn't exist yet. Delete the swapfile to have it resized on next boot.
    systemd.services.swapfile-create =
      mkIf (cfg.swap == "zswap" && any ({ device, ... }: device == "/swap/swapfile") config.swapDevices)
        {
          description = "Create swapfile sized relative to the root filesystem and RAM";
          wantedBy = [ "swap-swapfile.swap" ];
          before = [
            "swap-swapfile.swap"
            "shutdown.target"
          ];
          conflicts = [ "shutdown.target" ];
          unitConfig = {
            DefaultDependencies = false;
            RequiresMountsFor = [ "/swap" ];
            ConditionPathExists = "!/swap/swapfile";
          };
          serviceConfig.Type = "oneshot";
          path = [
            pkgs.btrfs-progs
            pkgs.coreutils
            pkgs.gawk
          ];
          script = ''
            # Systems installed before the swap subvolume was added to the
            # repart definitions don't have it.
            if [[ ! -d /swap ]]; then
              btrfs subvolume create /swap
            fi

            # Half of RAM, capped at 10% of the filesystem
            fs_size_mib=$(df --block-size=1M --output=size / | tail -n1)
            mem_size_mib=$(($(awk '/^MemTotal:/ { print $2 }' /proc/meminfo) / 1024))
            swap_size_mib=$((mem_size_mib / 2))
            max_size_mib=$((fs_size_mib / 10))
            swap_size_mib=$((swap_size_mib > max_size_mib ? max_size_mib : swap_size_mib))

            # Create under a temporary name so that an interrupted run doesn't
            # leave a partial swapfile in place.
            rm -f /swap/swapfile.tmp
            btrfs filesystem mkswapfile --size "''${swap_size_mib}M" --uuid clear /swap/swapfile.tmp
            mv /swap/swapfile.tmp /swap/swapfile
          '';
        };

    system.build = {
      inherit recovery;

      # Add hydra-build-products so that the recovery images can be downloaded
      # from the web UI.
      recoveryImage = recovery.config.system.build.image.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          mkdir -p $out/nix-support
          echo "file recovery-image $out/recovery.raw.zst" >> $out/nix-support/hydra-build-products
        '';
      });
    };
  };
}
