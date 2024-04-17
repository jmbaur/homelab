{ lib, ... }:
{
  imports = [
    ./uefi
    ./fit-image
    ./bootloaderspec
  ];

  options.custom.image.boot =
    with lib;
    mkOption {
      type = types.attrTag {
        uefi = mkOption {
          type = types.submodule {
            options = {
              enable = mkEnableOption "booting via UEFI";
            };
          };
        };
        uboot = mkOption {
          type = types.submodule {
            options = {
              enable = mkEnableOption "booting via U-Boot FIT image";

              kernelLoadAddress = mkOption {
                type = types.str;
                description = ''
                  TODO
                '';
              };

              bootMedium = {
                type = mkOption {
                  type = types.enum [
                    "mmc"
                    "scsi"
                    "nvme"
                    "usb"
                    "virtio"
                  ];
                  description = ''
                    TODO
                  '';
                };
                index = mkOption {
                  type = types.int;
                  default = 0;
                  description = ''
                    TODO
                  '';
                };
              };
            };
          };
        };
        bootLoaderSpec = mkOption {
          type = types.submodule {
            options = {
              enable = mkEnableOption "booting via Boot Loader Specification";
            };
          };
        };
      };
      description = ''
        The bootflow to setup for the disk image.
      '';
    };
}
