{ lib, ... }:
with lib;
{
  options.custom.laptop.enable = mkEnableOption "laptop configurations";
}
