{ lib, nixosTest, zstd }:

lib.genAttrs [ "immutable" "mutable" ] (test: nixosTest {
  name = "${test}-image";
  nodes.machine = { lib, ... }: {
    imports = [ ../nixos-modules/image ];

    nix.settings.experimental-features = [ "nix-command" ];

    boot.initrd.systemd.emergencyAccess = true;

    virtualisation.directBoot.enable = false;
    virtualisation.mountHostNixStore = false;
    virtualisation.useEFIBoot = true;

    # Make the qemu-vm.nix module use what is found under
    # `config.fileSystems`.
    virtualisation.fileSystems = lib.mkForce { };

    custom.image = {
      enable = true;
      primaryDisk = "/dev/vda";
      immutableMaxSize = 512 * 1024 * 1024; # 512M
      mutableNixStore = test == "mutable";
    };
  };

  testScript = { nodes, ... }: ''
    import os
    import subprocess
    import tempfile

    tmp_disk_image = tempfile.NamedTemporaryFile()

    subprocess.run([
      "${lib.getExe' zstd "zstd"}",
      "-d",
      "-o",
      "image.raw",
      "${nodes.machine.system.build.image}/image.raw.zst",
    ])
    subprocess.run([
      "${nodes.machine.virtualisation.qemu.package}/bin/qemu-img",
      "create",
      "-f",
      "qcow2",
      "-b",
      "image.raw",
      "-F",
      "raw",
      tmp_disk_image.name,
      "2G",
    ])

    # Set NIX_DISK_IMAGE so that the qemu script finds the right disk image.
    os.environ['NIX_DISK_IMAGE'] = tmp_disk_image.name

    bootctl_status = machine.succeed("bootctl status")

    with subtest("nix utilities"):
      machine.fail("command -v nixos-rebuild")
      machine.fail("test -f /run/current-system/bin/switch-to-configuration")

    with subtest("${test} nix store"):
      ${if test == "immutable" then ''
      machine.fail("touch foo && nix store add-file ./foo")
      '' else ''
      machine.succeed("touch foo && nix store add-file ./foo")
      ''}
  '';
})
