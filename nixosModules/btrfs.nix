{ config, lib, pkgs, ... }:
let
  btrfsMounts = lib.filterAttrs (_: mount: mount.fsType == "btrfs") config.fileSystems;
  hasHomeSubvolume = (lib.filterAttrs (_: mount: mount.mountPoint == "/home") btrfsMounts) != { };
in
{
  config = lib.mkIf (btrfsMounts != { }) {
    systemd.tmpfiles.rules = [ "d /var/lib/snapshots - root root 30d -" ];
    systemd.timers.snapshot-home = {
      enable = hasHomeSubvolume;
      description = "snapshot home subvolume";
      timerConfig.OnCalendar = "weekly";
      wantedBy = [ "multi-user.target" ];
    };
    systemd.services.snapshot-home = {
      enable = hasHomeSubvolume;
      path = [ pkgs.btrfs-progs ];
      script = "btrfs subvolume snapshot /home /var/lib/snapshots/$(date +%s)";
    };
  };
}
