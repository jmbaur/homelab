{ config, lib, pkgs, ... }:
let
  squashfsImage = pkgs.callPackage "${pkgs.path}/nixos/lib/make-squashfs.nix" {
    storeContents = [ config.system.build.toplevel ];
  };
in
{
  options.custom.tinyboot-installer.enable = lib.mkEnableOption "tinyboot installer";

  config = lib.mkIf config.custom.tinyboot-installer.enable {
    assertions = [{ assertion = config.tinyboot.enable; message = "tinyboot not enabled"; }];

    disko.devices = {
      disk.usb-stick = {
        device = "/dev/null";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "ESP";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            nix = {
              size = "100%";
              label = "NIX_RO_STORE";
            };
          };
          postCreateHook = ''
            dd if=${squashfsImage} of=/dev/disk/by-partlabel/NIX_RO_STORE
          '';
        };
      };
    };

    fileSystems = with lib; {
      "/" = mkImageMediaOverride {
        fsType = "tmpfs";
        options = [ "mode=0755" ];
      };

      "/nix/.ro-store" = mkImageMediaOverride {
        fsType = "squashfs";
        device = "/dev/disk/by-partlabel/NIX_RO_STORE";
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
  };
}
