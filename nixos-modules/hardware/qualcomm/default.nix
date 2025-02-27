{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.hardware.qualcomm.enable = lib.mkEnableOption "qualcomm";

  config = lib.mkIf config.hardware.qualcomm.enable {
    systemd.packages = [
      pkgs.qrtr
      pkgs.rmtfs
      pkgs.pd-mapper
    ];
  };
}
