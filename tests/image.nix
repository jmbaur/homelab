{ lib, nixosTest, zstd }:

let
  version = "0.0.0";
  newerVersion = "0.0.1";

  baseConfig = { config, lib, ... }: {
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

    fileSystems =
      let
        mkSharedDir = tag: share: {
          name = share.target;
          value.device = tag;
          value.fsType = "9p";
          value.neededForBoot = true;
          value.options = [ "trans=virtio" "version=9p2000.L" "msize=${toString config.virtualisation.msize}" ];
        };
      in
      lib.mapAttrs' mkSharedDir config.virtualisation.sharedDirectories;

    virtualisation.sharedDirectories = {
      xchg = {
        source = ''"$TMPDIR"/xchg'';
        target = "/tmp/xchg";
      };
      shared = {
        source = ''"''${SHARED_DIR:-$TMPDIR/xchg}"'';
        target = "/tmp/shared";
      };
    };

    custom.image = {
      enable = true;
      inherit version;
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
      import json
      import os
      import subprocess
      import tempfile
      import uuid

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

      def assert_boot_entry(filename: str):
          booted_entry = machine.succeed("iconv -f UTF-16 -t UTF-8 /sys/firmware/efi/efivars/LoaderEntrySelected-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f").strip('\x06').strip('\x00')
          if booted_entry != filename:
              raise Exception(f"booted from the wrong entry, expected {filename}, got {booted_entry}")

      assert_boot_entry("nixos-${version}.efi")

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
      machine.${if nodes.machine.custom.image.mutableNixStore then "succeed" else "fail"}("test -f /run/current-system/bin/switch-to-configuration")
      machine.${if nodes.machine.custom.image.mutableNixStore then "succeed" else "fail"}("touch foo && nix store add-file ./foo")

      # ensure security wrappers are mounted
      machine.succeed("test -d /run/wrappers/bin")

      # Force a fake update. Nothing is actually getting updated here, we are
      # just writing the same system image to the inactive update partition and
      # booting into it by telling systemd-boot that the UKI is newer than the
      # current one.
      #
      # TODO(jared): use systemd-sysupdate for this
      machine.copy_from_host("${nodes.machine.system.build.image}/image.usr.raw.zst", "image.usr.raw.zst")
      machine.succeed("zstd -d <image.usr.raw.zst | dd bs=4M of=/dev/disk/by-partlabel/usr-b")
      machine.succeed("rm image.usr.raw.zst")
      machine.copy_from_host("${nodes.machine.system.build.image}/image.usr-hash.raw.zst", "image.usr-hash.raw.zst")
      machine.succeed("zstd -d <image.usr-hash.raw.zst | dd bs=4M of=/dev/disk/by-partlabel/usr-b-hash")
      machine.succeed("rm image.usr-hash.raw.zst")
      machine.copy_from_host("${nodes.machine.system.build.image}/uki.efi", "${nodes.machine.boot.loader.efi.efiSysMountPoint}/efi/linux/nixos-${newerVersion}.efi")

      # Since the partition UUIDs are derived from the roothash of the
      # dm-verity device and we are writing the same dm-verity partitions to
      # the "B" update partitions, we must falsify the "A" update partitions
      # with fake UUIDs to ensure they are different. With a real update that
      # actually has a different dm-verity roothash, this hack wouldn't be
      # necessary.
      with open("${nodes.machine.system.build.image}/repart-output.json") as f:
          repart_output = json.load(f)
          hash_uuid = uuid.UUID(repart_output[2]["roothash"][32:])
          data_uuid = uuid.UUID(repart_output[2]["roothash"][:32])
          machine.succeed(f"sfdisk --part-uuid /dev/vda 2 {uuid.uuid4()}")
          machine.succeed(f"sfdisk --part-uuid /dev/vda 3 {uuid.uuid4()}")
          machine.succeed(f"sfdisk --part-uuid /dev/vda 4 {hash_uuid}")
          machine.succeed(f"sfdisk --part-uuid /dev/vda 5 {data_uuid}")

      machine.shutdown()

      assert_boot_entry("nixos-${newerVersion}.efi")
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
