{ config, lib, pkgs, ... }: {
  boot.loader.systemd-boot.enable = true;
  boot.growPartition = true;
  boot.loader.efi.canTouchEfiVariables = false;

  lib.isoFileSystems = with lib; {
    "/" = mkImageMediaOverride {
      fsType = "tmpfs";
      options = [ "mode=0755" ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
      options = [ "ro" ];
    };

    "/ro" = mkImageMediaOverride {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      options = [ "ro" ];
      neededForBoot = true;
    };

    "/nix/.ro-store" = mkImageMediaOverride {
      fsType = "bind";
      device = "/ro/nix/store";
      neededForBoot = true;
    };

    "/nix/.rw-store" = mkImageMediaOverride {
      fsType = "tmpfs";
      options = [ "mode=0755" ];
      neededForBoot = true;
    };

    "/nix/store" = mkImageMediaOverride {
      fsType = "overlay";
      device = "overlay";
      options = [
        "lowerdir=/nix/.ro-store"
        "upperdir=/nix/.rw-store/store"
        "workdir=/nix/.rw-store/work"
      ];
      depends = [
        "/nix/.ro-store"
        "/nix/.rw-store/store"
        "/nix/.rw-store/work"
      ];
    };
  };

  fileSystems = config.lib.isoFileSystems;

  system.build.sdImage = import (pkgs.path + "/nixos/lib/make-disk-image.nix") {
    name = "sd-image";
    inherit pkgs lib config;
    partitionTableType = "efi";
    format = "raw";
  };
}
