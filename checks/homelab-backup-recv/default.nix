{
  inputs,
  lib,
  testers,
}:

testers.runNixOSTest {
  name = "homelab-backup-recv";

  extraBaseModules.imports = [ inputs.self.nixosModules.default ];

  node.pkgs = lib.mkForce null;

  nodes.machine =
    { pkgs, lib, ... }:
    {
      virtualisation.emptyDiskImages = [ 512 ];

      boot.supportedFilesystems.btrfs = true;

      systemd.services.backup-recv = {
        path = [ pkgs.btrfs-progs ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = toString [
          (lib.getExe pkgs.homelab-backup-recv)
          (pkgs.writeText "peer-file.txt" ''
            localhost ::1
          '')
          "/disk/backups"
          4000
        ];
      };
    };

  testScript = ''
    machine.succeed("mkfs.btrfs /dev/vdb")
    machine.succeed("mount -oX-mount.mkdir /dev/vdb /disk")
    machine.succeed("btrfs subvolume create /disk/1")
    machine.succeed("btrfs subvolume create /disk/backups")
    machine.succeed("btrfs subvolume snapshot -r /disk/1 /disk/1.snapshot")
    machine.wait_for_unit("backup-recv")
    machine.succeed("btrfs send /disk/1.snapshot | nc -Nv ::1 4000")
    machine.succeed("test -d /disk/backups/localhost/1.snapshot")
  '';
}
