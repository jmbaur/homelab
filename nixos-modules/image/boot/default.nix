{ lib, ... }:
{
  imports = [
    ./uefi
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
