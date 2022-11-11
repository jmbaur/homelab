{ lib, systemConfig, ... }:
{
  options.custom.laptop.enable = lib.mkOption {
    type = lib.types.bool;
    default = systemConfig.custom.laptop.enable;
  };
}
