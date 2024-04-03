{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.hardware.chromebook.mediatek = lib.mkEnableOption "mediatek chromebook";
  config = lib.mkIf config.hardware.chromebook.mediatek {
    boot.kernelPackages = pkgs.linuxPackages_latest;
  };
}
