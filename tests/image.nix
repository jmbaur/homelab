{ lib, nixosTest, zstd }:

let
  baseConfig = { lib, ... }: {
    imports = [ ../nixos-modules/image ];

    nix.settings.experimental-features = [ "nix-command" ];

    boot.loader.timeout = 0;
    boot.initrd.systemd.emergencyAccess = true;

    virtualisation.directBoot.enable = false;
    virtualisation.mountHostNixStore = false;
    virtualisation.useEFIBoot = true;

    # Make the qemu-vm.nix module use what is found under
    # `config.fileSystems`.
    virtualisation.fileSystems = lib.mkForce { };
    virtualisation.useDefaultFilesystems = false;

    custom.image = {
      enable = true;
      version = "0.0.0";
      primaryDisk = "/dev/vda";
      immutableMaxSize = 512 * 1024 * 1024; # 512M
    };
  };
in
lib.mapAttrs'
  (test: nixosConfig:
  let
    name = "image-${test}";
  in
  lib.nameValuePair name (nixosTest {
    inherit name;

    nodes.machine = { imports = [ baseConfig nixosConfig ]; };

    testScript = { nodes, ... }: ''
      import os
      import subprocess
      import tempfile

      tmp_backing_file_image = tempfile.NamedTemporaryFile()
      tmp_disk_image = tempfile.NamedTemporaryFile()

      subprocess.run([
        "${lib.getExe' zstd "zstd"}",
        "--force",
        "--decompress",
        "-o",
        tmp_backing_file_image.name,
        "${nodes.machine.system.build.image}/image.raw.zst",
      ])

      subprocess.run([
        "${nodes.machine.virtualisation.qemu.package}/bin/qemu-img",
        "create",
        "-f",
        "qcow2",
        "-b",
        tmp_backing_file_image.name,
        "-F",
        "raw",
        tmp_disk_image.name,
        "2G",
      ])

      # Set NIX_DISK_IMAGE so that the qemu script finds the right disk image.
      os.environ['NIX_DISK_IMAGE'] = tmp_disk_image.name

      machine.start(allow_reboot=True)

      bootctl_status = machine.succeed("bootctl status")

      def disk_size(partlabel):
        return machine.succeed(f"blockdev --getsize64 /dev/disk/by-partlabel/{partlabel}").strip()

      if disk_size("usr-a") != disk_size("usr-b"):
        raise Exception("mismatching usr disk sizes")

      if disk_size("usr-a-hash") != disk_size("usr-b-hash"):
        raise Exception("mismatching usr-hash disk sizes")

      machine.succeed("test -f /nix/.ro-store/.nix-path-registration")
      ${lib.optionalString nodes.machine.custom.image.mutableNixStore ''
      machine.succeed("test $(nix-store --dump-db | wc -l) -gt 0")
      ''}

      machine.fail("command -v nixos-rebuild")
      machine.fail("test -f /run/current-system/bin/switch-to-configuration")

      machine.${if nodes.machine.custom.image.mutableNixStore then "succeed" else "fail"}("touch foo && nix store add-file ./foo")

      # ensure security wrappers are mounted
      machine.succeed("test -d /run/wrappers/bin")

      # TODO(jared): do an update, then reboot
      machine.shutdown()

      bootctl_status = machine.succeed("bootctl status")
    '';
  }))
{
  immutable = { };
  mutable = { custom.image.mutableNixStore = true; };
  unencrypted = { custom.image.encrypt = false; };
  tpm2-encrypted = {
    virtualisation.tpm.enable = true;
    custom.image.hasTpm2 = true;
  };
}
