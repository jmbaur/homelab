{ config, lib, pkgs, ... }:
let
  btrfsMounts = lib.filterAttrs (_: mount: mount.fsType == "btrfs") config.fileSystems;
  hasHomeSubvolume = (lib.filterAttrs (_: mount: mount.mountPoint == "/home") btrfsMounts) != { };
in
{
  config = lib.mkIf (btrfsMounts != { }) {
    systemd.tmpfiles.settings."10-snapshots"."/var/lib/snapshots".d = {
      user = "root";
      group = "root";
      age = "30d";
    };
    systemd.timers.snapshot-home = {
      enable = hasHomeSubvolume;
      description = "snapshot home subvolume";
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
      wantedBy = [ "multi-user.target" ];
    };
    systemd.services.snapshot-home = {
      enable = hasHomeSubvolume;
      path = [ pkgs.btrfs-progs ];
      script = "btrfs subvolume snapshot /home /var/lib/snapshots/$(date +%s)";
    };
  };
}
