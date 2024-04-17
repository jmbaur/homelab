{
  lib,
  stdenv,
  nixosTest,
  xz,
}:

let
  version = "0.1.0";
  newerVersion = "0.1.1";

  linuxUsrPartitionTypeUuid =
    {
      "x86_64" = "8484680C-9521-48C6-9C11-B0720656F69E";
      "aarch64" = "B0E01050-EE5F-4390-949A-9101B17104E9";
    }
    .${stdenv.hostPlatform.qemuArch};

  linuxUsrVerityPartitionTypeUuid =
    {
      "x86_64" = "8F461B0D-14EE-4E81-9AA9-049B6FB97ABD";
      "aarch64" = "6E11A4E7-FBCA-4DED-B9E9-E1A512BB664E";
    }
    .${stdenv.hostPlatform.qemuArch};

  baseConfig =
    { config, lib, ... }:
    {
      imports = [ ../nixos-modules/image ];

      nix.settings.experimental-features = [ "nix-command" ];

      boot.loader.timeout = 0;
      boot.initrd.systemd.emergencyAccess = true;

      virtualisation.directBoot.enable = false;
      virtualisation.mountHostNixStore = false;

      # enough space to store update images under /run
      virtualisation.memorySize = 2048;

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
            value.options = [
              "trans=virtio"
              "version=9p2000.L"
              "msize=${toString config.virtualisation.msize}"
            ];
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

      system.image.id = config.system.nixos.distroId;
      system.image.version = version;
      custom.image = {
        enable = true;
        primaryDisk = "/dev/vda";
        sectorSize = 512; # OVMF only supports 512B sector size?
        immutableMaxSize = 512 * 1024 * 1024; # 512M
      };
    };

  bootMethodConfig = {
    uefi = {
      custom.image.boot.uefi.enable = true;
      virtualisation.useEFIBoot = true;
    };
    fit-image =
      { pkgs, ... }:
      {
        custom.image.boot.uboot.enable = true;
        custom.image.boot.uboot.bootMedium.type = "virtio";
        custom.image.boot.uboot.kernelLoadAddress =
          if pkgs.stdenv.hostPlatform.isx86_64 then
            "0x01000000"
          else
            throw "don't know what load address should be";
        virtualisation.bios = pkgs.linkFarm "u-boot-nixos-vm-bios" [
          {
            name = "bios.bin";
            path =
              {
                x86_64 = "${
                  pkgs.uboot-qemu-x86_64.override {
                    extraStructuredConfig = with lib.kernel; {
                      CMD_LZMADEC = yes;
                      SYS_LOAD_ADDR = freeform "0x04000000"; # allow for larger than 16MiB kernel size
                    };
                  }
                }/u-boot.rom";
                aarch64 = "${pkgs.uboot-qemu_arm64}/u-boot.bin";
              }
              .${pkgs.stdenv.hostPlatform.qemuArch};
          }
        ];
      };
  };

  imageTypeConfig = {
    immutable = { };
    mutable = {
      custom.image.mutableNixStore = true;
    };
    unencrypted = {
      custom.image.encrypt = false;
    };
    tpm2-encrypted = {
      virtualisation.tpm.enable = true;
      custom.image.hasTpm2 = true;
    };
  };
in
builtins.listToAttrs (
  map
    (
      { bootMethod, imageType }:
      let
        name = "image-${bootMethod}-${imageType}";
      in
      lib.nameValuePair name (nixosTest {
        inherit name;

        nodes.machine = {
          imports = [
            baseConfig
            bootMethodConfig.${bootMethod}
            imageTypeConfig.${imageType}
          ];
        };

        testScript =
          { nodes, ... }:
          ''
            import json
            import os
            import subprocess
            import tempfile
            import uuid

            tmp_backing_file_image = tempfile.NamedTemporaryFile()
            tmp_disk_image = tempfile.NamedTemporaryFile()

            with open(tmp_backing_file_image.name, "w") as outfile:
                subprocess.run([
                  "${lib.getExe' xz "xz"}",
                  "--force",
                  "--decompress",
                  "--stdout",
                  "${nodes.machine.system.build.image}/image.raw.xz",
                ], stdout=outfile)

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

            def assert_boot_entry(filename: str):
                booted_entry = machine.succeed("iconv -f UTF-16 -t UTF-8 /sys/firmware/efi/efivars/LoaderEntrySelected-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f").strip('\x06').strip('\x00')
                if booted_entry != filename:
                    raise Exception(f"booted from the wrong entry, expected {filename}, got {booted_entry}")

            assert_boot_entry("nixos_${version}.efi")

            partitions = json.loads(machine.succeed("sfdisk --json ${nodes.machine.custom.image.primaryDisk}"))["partitiontable"]["partitions"]

            def equal_elements(xs):
                return all([x == xs[0] for x in xs])

            usr_partitions = [p["size"] for p in partitions if p["type"] == "${linuxUsrPartitionTypeUuid}"]
            if not equal_elements(usr_partitions):
                raise Exception(f"mismatching usr disk sizes: {usr_partitions}")

            usr_hash_partitions = [p["size"] for p in partitions if p["type"] == "${linuxUsrVerityPartitionTypeUuid}"]
            if not equal_elements(usr_hash_partitions):
                raise Exception(f"mismatching usr-hash disk sizes: {usr_hash_partitions}")

            machine.succeed("test -f /nix/.ro-store/.nix-path-registration")
            ${lib.optionalString nodes.machine.custom.image.mutableNixStore ''
              machine.succeed("test $(nix-store --dump-db | wc -l) -gt 0")
            ''}

            machine.fail("command -v nixos-rebuild")
            machine.${
              if nodes.machine.custom.image.mutableNixStore then "succeed" else "fail"
            }("test -f /run/current-system/bin/switch-to-configuration")
            machine.${
              if nodes.machine.custom.image.mutableNixStore then "succeed" else "fail"
            }("touch foo && nix store add-file ./foo")

            machine.copy_from_host("${nodes.machine.system.build.image.update}", "/run/tmp")
            machine.succeed("mv /run/tmp/* /run/update")

            current_usr = machine.succeed("ls /run/update/*${version}*.usr.raw.xz").strip()
            current_usr_hash = machine.succeed("ls /run/update/*${version}*.usr-hash.raw.xz").strip()
            current_uki = machine.succeed("ls /run/update/*${version}*.efi").strip()

            machine.succeed("mv {} {}".format(current_usr, current_usr.replace("${version}", "${newerVersion}", 1)))
            machine.succeed("mv {} {}".format(current_usr_hash, current_usr_hash.replace("${version}", "${newerVersion}", 1)))
            machine.succeed("mv {} {}".format(current_uki, current_uki.replace("${version}", "${newerVersion}", 1)))

            machine.succeed("${nodes.machine.systemd.package}/lib/systemd/systemd-sysupdate update")
            machine.wait_for_console_text("Successfully installed update '${newerVersion}'.")

            # Since the partition UUIDs are derived from the roothash of the
            # dm-verity device and we are writing the same dm-verity partitions to
            # the "B" update partitions, we must falsify the "A" update partitions
            # with fake UUIDs to ensure they are different. With a real update that
            # actually has a different dm-verity roothash, this wouldn't be
            # necessary.
            machine.succeed(f"sfdisk --part-uuid /dev/vda 2 {uuid.uuid4()}")
            machine.succeed(f"sfdisk --part-uuid /dev/vda 3 {uuid.uuid4()}")

            machine.shutdown()

            assert_boot_entry("nixos_${newerVersion}+3-0.efi")
            machine.wait_for_unit("boot-complete.target")
            machine.wait_until_succeeds("test -f ${nodes.machine.boot.loader.efi.efiSysMountPoint}/EFI/Linux/nixos_${newerVersion}.efi")
          '';
      })
    )
    (
      # TODO(jared): test with all boot methods, right now uefi is easiest
      lib.filter ({ bootMethod, ... }: bootMethod == "uefi") (
        lib.cartesianProductOfSets {
          bootMethod = [
            "uefi"
            "fit-image"
            "bootloaderspec"
          ];
          imageType = [
            "immutable"
            "mutable"
            "unencrypted"
            "tpm2-encrypted"
          ];
        }
      )
    )
)
