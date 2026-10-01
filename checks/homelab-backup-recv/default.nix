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
    { pkgs, ... }:
    {
      imports = [ ../../nixos-configurations/backup.nix ];

      virtualisation.emptyDiskImages = [ 512 ];
      virtualisation.fileSystems."/disk" = {
        device = "/dev/vdb";
        fsType = "btrfs";
        autoFormat = true;
      };

      custom.backup.receiver = {
        enable = true;
        snapshotRoot = "/disk/backups";
      };
      custom.yggdrasil.peers.localhost.ip = "::1";

      environment.systemPackages = [
        pkgs.acl
        pkgs.attr
        pkgs.btrfs-progs
        pkgs.libcap
        pkgs.netcat
      ];
    };

  testScript = ''
    machine.wait_for_unit("backup-recv.service")

    # Metadata that btrfs-receive needs each of the service's capabilities to restore.
    machine.succeed(
      "btrfs subvolume create /disk/1",
      "cd /disk/1"
      " && mkdir private && echo secret > private/f && chown -R 1234:1234 private && chmod 700 private && chmod 600 private/f"
      " && echo x > owned && chown 4321:999 owned && setfattr -n user.foo -v bar owned"
      " && setfattr -n trusted.foo -v baz owned && setfacl -m u:1234:r owned"
      " && echo s > suid && chown 1000:100 suid && chmod 4755 suid"
      " && mkdir sgid && chown 1000:100 sgid && chmod 2775 sgid && mkdir sticky && chmod 1777 sticky"
      " && mkfifo fifo && mknod chr c 1 3 && ln -s target link && ln owned hardlink"
      " && echo c > capfile && setcap cap_net_raw+ep capfile"
      " && echo r > noperm && chmod 000 noperm && truncate -s 64M sparse",
      "btrfs subvolume snapshot -r /disk/1 /disk/1.snapshot",
    )

    machine.succeed("btrfs send /disk/1.snapshot | nc -N ::1 4000")
    machine.wait_until_succeeds("journalctl -u backup-recv | grep 'finished backup for peer localhost'")

    def manifest(d):
        return machine.succeed(
            f"cd {d} && for f in $(find . | sort); do"
            " echo \"$(stat -c '%n %F %a %u %g %s %t %T %Y' \"$f\") $(getfattr -h -d -m - --absolute-names \"$f\" | tail -n+2 | tr '\\n' ' ')\";"
            " done; find . -type f -exec sha256sum {} + | sort"
        )

    assert manifest("/disk/1.snapshot") == manifest("/disk/backups/localhost/1.snapshot")
    machine.succeed("btrfs subvolume show /disk/backups/localhost/1.snapshot | grep -E 'Received UUID:\\s+[0-9a-f]'")

    # Only known peers may connect at all.
    machine.fail("echo hi | timeout 5 nc -N 127.0.0.1 4000")

    print(machine.succeed("systemd-analyze security backup-recv.service | tail -1"))
  '';
}
