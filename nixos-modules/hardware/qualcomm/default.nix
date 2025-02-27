{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.hardware.qualcomm.enable = lib.mkEnableOption "qualcomm";

  # TODO(jared): we don't have to add some of these if wifi is not enabled?

  config = lib.mkIf config.hardware.qualcomm.enable {
    environment.systemPackages = [ pkgs.qrtr ];

    systemd.packages = [
      pkgs.pd-mapper
      pkgs.qrtr
      pkgs.rmtfs
      pkgs.tqftpserv
    ];

    systemd.services.rmtfs.serviceConfig.ExecStartPre = lib.getExe pkgs.msm-cros-efs-loader;
  };
}
