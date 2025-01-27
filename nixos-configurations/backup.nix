{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatLines
    getExe
    mapAttrs'
    mapAttrsToList
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.custom.backup;
in
{
  options.custom.backup = {
    receiver = {
      enable = mkEnableOption "backup receiver";

      snapshotRoot = mkOption {
        type = types.str;
        default = "/var/lib/backup";
      };

      port = mkOption {
        type = types.ints.positive;
        default = 4000;
      };
    };

    sender = {
      enable = mkEnableOption "backup sender";

      receiver = mkOption {
        type = types.nonEmptyStr;
        example = "2001:db8::1 4000";
        description = ''
          Reciever address in netcat-style syntax '<host> <port>'.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.receiver.enable {
      systemd.tmpfiles.settings."10-backup" = mapAttrs' (nodeName: _: {
        name = "${cfg.receiver.snapshotRoot}/${nodeName}";
        value.v.age = "1M";
      }) config.custom.yggdrasil.nodes;

      systemd.services.backup-recv = {
        path = [ pkgs.btrfs-progs ];
        serviceConfig.Type = "oneshot";
        serviceConfig.ExecStart = toString [
          (getExe pkgs.homelab-backup-recv)
          (pkgs.writeText "peer-file.txt" (
            concatLines (
              mapAttrsToList (
                nodeName: nodeSettings: "${nodeName} ${nodeSettings.ip}"
              ) config.custom.yggdrasil.nodes
            )
          ))
          cfg.receiver.snapshotRoot
          cfg.receiver.port
        ];
      };
    })

    (mkIf cfg.sender.enable {
      systemd.tmpfiles.settings."10-backup"."/snapshots".v.age = "1M";

      systemd.services.backup-send = {
        startAt = [ "weekly" ];
        serviceConfig.Type = "oneshot";
        serviceConfig.ExecStart = getExe (
          pkgs.writeShellApplication {
            name = "backup-send";

            runtimeInputs = [
              pkgs.libressl.nc
              pkgs.btrfs-progs
            ];

            text = ''
              snapshot=/snapshots/$(date --rfc-3339=date)
              btrfs snapshot -r / "$snapshot"
              btrfs send "$snapshot" | nc -N ${cfg.sender.receiver}
            '';
          }
        );
      };
    })
  ];
}
