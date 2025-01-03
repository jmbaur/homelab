{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.hardware.qualcomm.enable = lib.mkEnableOption "qualcomm";

  config = lib.mkIf config.hardware.qualcomm.enable {
    systemd.services.pd-mapper = {
      description = "Qualcomm PD mapper service";
      requires = [ "qrtr-ns.service" ];
      after = [ "qrtr-ns.service" ];
      serviceConfig = {
        Restart = "always";
        ExecStart = lib.getExe pkgs.pd-mapper;
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.qrtr-ns = {
      description = "QIPCRTR Name Service";
      serviceConfig = {
        ExecStart = "${lib.getExe' pkgs.qrtr "qrtr-ns"} -f 1";
        Restart = "always";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
