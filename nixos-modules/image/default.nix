{ config, lib, pkgs, modulesPath, ... }:

let
  cfg = config.custom.image;

  testActiveNixStorePartition = pkgs.writeScript "test-active-nix-store-partition" ''
    #!/bin/bash
    [[ "$1" == "$2" ]] && echo -n active || echo -n inactive
  '';
in
{
  options.custom.image = with lib; {
    enable = mkEnableOption "TODO";

    rootDevicePath = mkOption {
      type = types.path;
      description = mdDoc ''
        TODO
      '';
    };

    bootVariant = mkOption {
      type = types.enum [ "uefi" "fit-image" ];
      default = "uefi";
    };

    ubootBootMedium = {
      type = mkOption {
        type = types.enum [ "mmc" "nvme" "usb" ];
      };
      index = mkOption {
        type = types.int;
        default = 0;
      };
    };
  };

  imports = [
    "${modulesPath}/image/repart.nix" # TODO(jared): why isn't this included in nixpkgs?
    ./boot/uefi.nix
    ./boot/fit-image.nix
  ];

  config = lib.mkIf cfg.enable {
    # we don't need nixpkgs boot-loading infrastructure
    boot.loader.grub.enable = false;

    image.repart = {
      name = "image";
      split = true;
      partitions.nixosPartitionA = {
        storePaths = [ config.system.build.toplevel ];
        stripNixStorePrefix = true;
        repartConfig = config.systemd.repart.partitions.nixosPartitionA // {
          # 512M of wiggle room for future updates
          PaddingMinBytes = "512M";
          PaddingMaxBytes = "512M";
        };
      };
    };

    boot.initrd = {
      systemd.enable = true;
      systemd.repart = {
        enable = true;
        # this needs to be set in order to create the root partition
        # dynamically on first boot
        device = cfg.rootDevicePath;
      };

      # There's gotta be a way to test simple equality in native udev, not shell
      # out to bash or something...
      systemd.storePaths = [ testActiveNixStorePartition ];
      services.udev.rules = ''
        SUBSYSTEM!="block", GOTO="active_nixos_partition_end"
        ENV{ID_PART_ENTRY_NAME}=="nixos-[ab]", IMPORT{cmdline}="nixos.active"
        ENV{ID_PART_ENTRY_NAME}=="nixos-[ab]", PROGRAM="${testActiveNixStorePartition} $env{ID_PART_ENTRY_NAME} $env{nixos.active}", SYMLINK+="disk/nixos/%c", TAG="systemd"
        LABEL="active_nixos_partition_end"
      '';
    };

    systemd.repart.partitions = {
      nixosPartitionA = {
        # we call this a "usr" type, but systemd's meaning of "usr" maps to
        # our use case of anything that is static (i.e. the toplevel
        # derivation of a nixos system).
        Type = "usr-${pkgs.stdenv.hostPlatform.linuxArch}";
        Label = "nixos-a";
        Format = "erofs";
        Minimize = "best";
        SplitName = "nixos";
        # This partition is populated at image creation time, but in order for
        # systemd-repart to work in the initrd, it needs to think it has to do
        # some "work", such as creating the root directory of the partition.
        MakeDirectories = "/";
      };

      # TODO(jared): doesn't work since systemd-repart starts before
      # systemd-udevd gets to resolve the disk partition label symlink
      # # The "B" update partition and state partition get created on first boot.
      # nixosPartitionB = {
      #   Type = "usr-${pkgs.stdenv.hostPlatform.linuxArch}";
      #   Label = "nixos-b";
      #   CopyBlocks = "/dev/disk/by-partlabel/nixos-a";
      # };

      state = {
        Type = "linux-generic";
        Label = "state";
        Format = "btrfs";
        MakeDirectories = toString [ "/home" "/var" "/etc" ];
      };
    };

    fileSystems."/" = {
      fsType = "tmpfs";
      device = "none";
      neededForBoot = true;
    };
    fileSystems."/nix/store" = {
      fsType = config.systemd.repart.partitions.nixosPartitionA.Format;
      device = "/dev/disk/by-partlabel/nixos-a"; # TODO(jared): /dev/disk/nixos/active
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-partlabel/${config.image.repart.partitions.boot.repartConfig.Label}";
      fsType = config.image.repart.partitions.boot.repartConfig.Format;
      options = [ "x-systemd.automount" ];
    };
    fileSystems."/state" = {
      fsType = config.systemd.repart.partitions.state.Format;
      device = "/dev/disk/by-partlabel/${config.systemd.repart.partitions.state.Label}";
      neededForBoot = true;
    };
    fileSystems."/etc" = {
      device = "/state/etc";
      options = [ "bind" ];
      neededForBoot = true;
    };
    fileSystems."/var" = {
      device = "/state/var";
      options = [ "bind" ];
      neededForBoot = true;
    };
    fileSystems."/home" = {
      device = "/state/home";
      options = [ "bind" ];
      neededForBoot = true;
    };

    boot.postBootCommands = ''
      if [ -f /nix-path-registration ]; then
        ${lib.getExe' config.nix.package "nix-store"} --load-db < /nix-path-registration
        rm -f /nix-path-registration
      fi
    '';
  };
}
