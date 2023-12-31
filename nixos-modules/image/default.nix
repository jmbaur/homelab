{ config, lib, pkgs, ... }:

let
  cfg = config.custom.image;

  verityHashSize = "128M";
in
{
  options.custom.image = with lib; {
    enable = mkEnableOption "TODO";

    bootFileCommands = mkOption {
      type = types.lines;
      default = "";
      description = mdDoc ''
        TODO
      '';
    };

    rootDevicePath = mkOption {
      type = types.path;
      description = mdDoc ''
        TODO
      '';
    };

    rootSize = mkOption {
      type = types.str;
      default = "2G";
      description = mdDoc ''
        TODO
      '';
    };

    bootVariant = mkOption {
      type = types.enum [ "uefi" "fit-image" ];
      default = "uefi";
      description = mdDoc ''
        TODO
      '';
    };

    ubootBootMedium = {
      type = mkOption {
        type = types.enum [ "mmc" "nvme" "usb" ];
        description = mdDoc ''
          TODO
        '';
      };
      index = mkOption {
        type = types.int;
        default = 0;
        description = mdDoc ''
          TODO
        '';
      };
    };
  };

  imports = [
    ./boot/uefi.nix
    ./boot/fit-image.nix
  ];

  config = lib.mkIf cfg.enable {
    # we don't need nixpkgs boot-loading infrastructure
    boot.loader.grub.enable = false;

    boot.kernelParams = [
      "systemd.verity_root_options=panic-on-corruption"

      # Tell systemd to not automount anything on /usr. We don't
      # actually have a /usr mount in our fstab...
      "mount.usr=fstab"
    ];

    # We do this because we need the udev rules and some binaries from the lvm2
    # package.
    boot.initrd.services.lvm.enable = true;

    boot.initrd = {
      systemd = {
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
        services.systemd-repart.after = [ "dev-mapper-usr.device" ];
        services.systemd-repart.requires = [ "dev-mapper-usr.device" ];

        # This needs to be set in order to create the root partition
        # dynamically on first boot.
        repart.device = cfg.rootDevicePath;
      };

      availableKernelModules = [ "dm-verity" ];
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
        SizeMinBytes = cfg.rootSize;
        SizeMaxBytes = cfg.rootSize;
      };
      "20-usr-a-hash" = {
        Type = "usr-verity";
        Label = "usr-a-hash";
        SizeMinBytes = verityHashSize;
        SizeMaxBytes = verityHashSize;
      };

      # The "B" update partition and root partition get created on first boot.
      "20-usr-b" = {
        Type = "usr";
        Label = "usr-b";
        SizeMinBytes = cfg.rootSize;
        SizeMaxBytes = cfg.rootSize;
      };
      "20-usr-b-hash" = {
        Type = "usr-verity";
        Label = "usr-b-hash";
        SizeMinBytes = verityHashSize;
        SizeMaxBytes = verityHashSize;
      };
      "30-root" = {
        Type = "root";
        Label = "root";
        Format = "btrfs";
        FactoryReset = true;
      };
    };

    fileSystems."/" = {
      device = "/dev/disk/by-partlabel/${config.systemd.repart.partitions."30-root".Label}";
      fsType = config.systemd.repart.partitions."30-root".Format;
    };
    fileSystems."/nix/store" = {
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

    boot.postBootCommands = ''
      if [ -f /nix-path-registration ]; then
        ${lib.getExe' config.nix.package "nix-store"} --load-db < /nix-path-registration
        rm -f /nix-path-registration
      fi
    '';

    system.build.image = pkgs.callPackage ./image.nix {
      usrFormat = config.fileSystems."/nix/store".fsType;
      inherit (cfg) bootFileCommands;
      inherit (config.system.build) toplevel;
      inherit (config.systemd.repart) partitions;
    };
  };
}
