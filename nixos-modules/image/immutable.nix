{ config, lib, pkgs, ... }:

let
  cfg = config.custom.image.immutable;

  nixosRepartPartitionFor =
    # the A or B slot partition
    partSlot:
    {
      # we call this a "usr" type, but systemd's meaning of "usr" maps to
      # our use case of anything that is static (i.e. the toplevel
      # derivation of a nixos system).
      Type = "usr-${pkgs.stdenv.hostPlatform.qemuArch}";
      Label = "nixos-${partSlot}";
      Format = "erofs";
      Minimize = "best";
      SplitName = "nixos";
      # # 512M of wiggle room for future updates
      PaddingMinBytes = "512M";
      PaddingMaxBytes = "512M";
    };

  systemdUkify = pkgs.buildPackages.systemdMinimal.override {
    withEfi = true;
    withUkify = true;
    withBootloader = true;
  };

  nixosUki = pkgs.runCommand "nixos-uki.efi" { } ''
    ${systemdUkify}/lib/systemd/ukify build \
      --linux=${config.system.build.kernel}/${config.system.boot.loader.kernelFile} \
      --cmdline="init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}" \
      --initrd=${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile} \
      --os-release=@${config.environment.etc."os-release".source} \
      --output=$out
  '';

  systemdBoot = "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${pkgs.stdenv.hostPlatform.efiArch}.efi";

  testActiveNixStorePartition = pkgs.writeScript "test-active-nix-store-partition" ''
    #!/bin/bash
    [[ "$1" == "$2" ]] && echo -n active || echo -n inactive
  '';
in
{
  options.custom.image.immutable = {
    enable = lib.mkEnableOption "immutable image";
  };

  config = lib.mkIf cfg.enable {
    # TODO(jared): don't hardcode this! Do something like this:

    image.repart = {
      name = "image";
      split = true;
      partitions = {
        boot = {
          contents = {
            "/EFI/BOOT/BOOT${lib.toUpper pkgs.stdenv.hostPlatform.efiArch}.EFI".source = systemdBoot;
            "/EFI/Linux/nixos${config.system.nixos.versionSuffix}.efi".source = nixosUki;
          };
          repartConfig = {
            Type = "esp";
            Label = "BOOT";
            Format = "vfat";
            SizeMinBytes = "256M";
            SizeMaxBytes = "256M";
          };
        };
        nixosPartitionA = {
          storePaths = [ config.system.build.toplevel ];
          stripNixStorePrefix = true;
          repartConfig = nixosRepartPartitionFor "a";
        };
      };
    };

    boot.initrd = {
      systemd.enable = true;
      systemd.repart.enable = true;

      # There's gotta be a way to test simple equality in native udev, not shell
      # out to bash or something...
      systemd.storePaths = [ testActiveNixStorePartition ];
      services.udev.rules = ''
        SUBSYSTEM!="block", GOTO="active_nixos_partition_end"
        ENV{ID_PART_ENTRY_NAME}=="nixos-[ab]", IMPORT{cmdline}="nixos.active"
        ENV{ID_PART_ENTRY_NAME}=="nixos-[ab]", PROGRAM="${testActiveNixStorePartition} $env{ID_PART_ENTRY_NAME} $env{nixos.active}", SYMLINK+="disk/nixos/%c", TAG="systemd"
        LABEL="active_nixos_partition_end"
      '';

      # https://www.freedesktop.org/software/systemd/man/latest/bootup.html#Bootup%20in%20the%20initrd
      systemd.mounts = [{
        where = "/sysroot/nix/store";
        what = "/dev/disk/nixos/active";
        type = config.image.repart.partitions.nixosPartitionA.repartConfig.Format;
        options = "ro";
        wantedBy = [ "initrd-fs.target" ];
        before = [ "initrd-fs.target" ];
      }];
    };

    systemd.repart.partitions = {
      # The "B" update partition and root partition get created on
      # first boot.
      nixosPartitionB = nixosRepartPartitionFor "b";
      root = {
        Type = "root-${pkgs.stdenv.hostPlatform.qemuArch}";
        Label = "root";
        Format = "btrfs";
      };
    };

    fileSystems."/" = {
      fsType = config.systemd.repart.partitions.root.Format;
      device = "/dev/disk/by-partlabel/${config.systemd.repart.partitions.root.Label}";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-partlabel/${config.image.repart.partitions.boot.repartConfig.Label}";
      fsType = config.image.repart.partitions.boot.repartConfig.Format;
      options = [ "x-systemd.automount" ];
    };

    boot.postBootCommands = ''
      if [ -f /nix-path-registration ]; then
        ${lib.getExe' config.nix.package "nix-store"} --load-db < /nix-path-registration
        rm -f /nix-path-registration
      fi
    '';
  };
}
