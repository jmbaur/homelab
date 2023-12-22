{ nixosTest }:

nixosTest {
  name = "immutable-image";
  nodes.machine = {
    imports = [ ../nixos-modules/image ];

    virtualisation.directBoot.enable = false;
    virtualisation.mountHostNixStore = false;
    virtualisation.useEFIBoot = true;

    # TODO(jared): this should be populated automatically, but maybe the
    # nixos test driver is messing with us?
    boot.initrd.supportedFilesystems = [ "squashfs" "erofs" "btrfs" "ext4" ];

    boot.kernelParams = [ "console=tty1" ];

    boot.loader.grub.enable = false;

    custom.image.immutable = {
      enable = true;
    };
  };

  testScript = { nodes, ... }: ''
    import os
    import subprocess
    import tempfile

    tmp_disk_image = tempfile.NamedTemporaryFile()

    subprocess.run([
      "${nodes.machine.virtualisation.qemu.package}/bin/qemu-img",
      "create",
      "-f",
      "qcow2",
      "-b",
      "${nodes.machine.system.build.image}/image.raw",
      "-F",
      "raw",
      tmp_disk_image.name,
    ])

    # Set NIX_DISK_IMAGE so that the qemu script finds the right disk image.
    os.environ['NIX_DISK_IMAGE'] = tmp_disk_image.name

    bootctl_status = machine.succeed("bootctl status")
  '';
}
