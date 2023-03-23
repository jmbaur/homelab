{ lib, nixosConfig, ... }:
{
  options.custom.laptop.enable = lib.mkOption {
    type = lib.types.bool;
    default = nixosConfig.custom.laptop.enable;
  };
}
