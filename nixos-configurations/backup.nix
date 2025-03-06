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
      }) config.custom.yggdrasil.peers;

      systemd.services.backup-recv = {
        path = [ pkgs.btrfs-progs ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = toString [
          (getExe pkgs.homelab-backup-recv)
          (pkgs.writeText "peer-file.txt" (
            concatLines (
              mapAttrsToList (
                nodeName: peerSettings: "${nodeName} ${peerSettings.ip}"
              ) config.custom.yggdrasil.peers
            )
          ))
          cfg.receiver.snapshotRoot
          cfg.receiver.port
        ];
      };
    })

    (mkIf cfg.sender.enable {
      systemd.tmpfiles.settings."10-backup"."/snapshots".v.age = "1M";

      systemd.timers.backup-send = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          RandomizedDelaySec = "4h";
          Persistent = true;
        };
      };

      systemd.services.backup-send.serviceConfig = {
        Type = "oneshot";
        ExecStart = getExe (
          pkgs.writeShellApplication {
            name = "backup-send";

            runtimeInputs = [
              pkgs.btrfs-progs
              pkgs.netcat
              pkgs.pv
            ];

            text = ''
              snapshot=/snapshots/$(date --rfc-3339=date)
              btrfs subvolume snapshot -r / "$snapshot"
              btrfs send "$snapshot" | pv --numeric --bytes | nc -Nv ${cfg.sender.receiver}
            '';
          }
        );
      };
    })
  ];
}
