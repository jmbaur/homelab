{ nixosTest }:

nixosTest {
  name = "immutable-image";
  nodes.machine = { lib, ... }: {
    imports = [ ../nixos-modules/image ];

    virtualisation.directBoot.enable = false;
    virtualisation.mountHostNixStore = false;
    virtualisation.useEFIBoot = true;

    # Make the qemu-vm.nix module use what is found under
    # `config.fileSystems`.
    virtualisation.fileSystems = lib.mkForce { };

    custom.image = {
      enable = true;
      rootDevicePath = "/dev/vda";
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
