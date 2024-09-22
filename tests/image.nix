{
  inputs,
  lib,
  nixosTest,
  stdenv,
  xz,
  gnupg,
  runCommand,
  emptyFile,
}:

let
  version = "0.1.0";
  newerVersion = "0.1.1";

  gpgKeyring = runCommand "gpg-keyring" { nativeBuildInputs = [ gnupg ]; } ''
    mkdir -p $out
    export GNUPGHOME=$out
    cat >foo <<EOF
      %echo Generating a basic OpenPGP key
      %no-protection
      Key-Type: EdDSA
      Key-Curve: ed25519
      Name-Real: Bob Foobar
      Name-Email: bob@foo.bar
      Expire-Date: 0
      # Do a commit here, so that we can later print "done"
      %commit
      %echo done
    EOF
    gpg --batch --generate-key foo
    rm $out/S.gpg-agent $out/S.gpg-agent.*
    gpg --export bob@foo.bar -a >$out/pubkey.gpg
  '';

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

  unpackImage =
    {
      config,
      imageAttr ? "image",
      envVar ? "NIX_DISK_IMAGE",
    }:
    ''
      tmp_backing_file_image = tempfile.NamedTemporaryFile()
      tmp_disk_image = tempfile.NamedTemporaryFile()

      with open(tmp_backing_file_image.name, "w") as outfile:
          subprocess.run([
            "${lib.getExe' xz "xz"}",
            "--force",
            "--decompress",
            "--stdout",
            "${config.system.build.${imageAttr}}/image.raw.xz",
          ], stdout=outfile)

      subprocess.run([
        "${config.virtualisation.qemu.package}/bin/qemu-img",
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

      # Set ${envVar} so that the qemu script finds the right disk image.
      os.environ['${envVar}'] = tmp_disk_image.name
    '';

  baseConfig =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.self.nixosModules.default ];

      assertions = [
        { assertion = builtins.elem "nix-command" config.nix.settings.experimental-features; }
      ];

      boot.kernelPackages = pkgs.linuxPackages_latest;

      boot.loader.timeout = 0;

      virtualisation.vlans = [ 1 ];

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

      # To test local-overlay store
      system.extraDependencies = [ emptyFile ];

      system.image.version = version;
      custom.image = {
        enable = true;
        sectorSize = 512; # OVMF only supports 512B sector size?
        wiggleRoom = 4096 * 8; # smaller than the default, we don't need any for this test
        installer.targetDisk = "/dev/vda";
        update = {
          source = "http://updateServer/${config.networking.hostName}";
          gpgPubkey = "${gpgKeyring}/pubkey.gpg";
        };
      };
    };

  bootMethodConfig = {
    uefi = {
      custom.image.boot.uefi.enable = true;
      virtualisation.useEFIBoot = true;
    };
    uboot =
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
    bootloaderspec = {
      custom.image.boot.bootLoaderSpec.enable = true;
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

  updateServer =
    { pkgs, ... }:
    {
      virtualisation.vlans = [ 1 ];
      environment.systemPackages = [ pkgs.gnupg ];
      systemd.tmpfiles.settings."10-sws-root"."/var/lib/updates".d = { };
      networking.firewall.allowedTCPPorts = [ 80 ];
      services.static-web-server = {
        enable = true;
        listen = "[::]:80";
        root = "/var/lib/updates";
      };
    };
in
(
  builtins.listToAttrs (
    map
      (
        { bootMethod, imageType }:
        let
          name = "image-${bootMethod}-${imageType}";
        in
        lib.nameValuePair name (nixosTest {
          inherit name;

          nodes = {
            inherit updateServer;

            machine = {
              imports = [
                baseConfig
                bootMethodConfig.${bootMethod}
                imageTypeConfig.${imageType}
              ];
            };
          };

          testScript =
            { nodes, ... }:
            ''
              import json
              import os
              import subprocess
              import tempfile
              import uuid

              updateServer.wait_for_unit("multi-user.target")

              ${unpackImage { config = nodes.machine; }}

              machine.wait_for_unit("multi-user.target")

              def assert_boot_entry(filename: str):
                  booted_entry = machine.succeed("iconv -f UTF-16 -t UTF-8 /sys/firmware/efi/efivars/LoaderEntrySelected-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f").strip('\x06').strip('\x00')
                  if booted_entry != filename:
                      raise Exception(f"booted from the wrong entry, expected {filename}, got {booted_entry}")

              assert_boot_entry("nixos_${version}+3-0.efi")

              partitions = json.loads(machine.succeed("sfdisk --json ${nodes.machine.custom.image.installer.targetDisk}"))["partitiontable"]["partitions"]

              def equal_elements(xs):
                  return all([x == xs[0] for x in xs])

              usr_partitions = [p["size"] for p in partitions if p["type"] == "${linuxUsrPartitionTypeUuid}"]
              if not equal_elements(usr_partitions):
                  raise Exception(f"mismatching usr disk sizes: {usr_partitions}")

              usr_hash_partitions = [p["size"] for p in partitions if p["type"] == "${linuxUsrVerityPartitionTypeUuid}"]
              if not equal_elements(usr_hash_partitions):
                  raise Exception(f"mismatching usr-hash disk sizes: {usr_hash_partitions}")

              with subtest("mutability"):
                  machine.fail("command -v nixos-rebuild")
                  if "${toString nodes.machine.custom.image.mutableNixStore}" == "1":
                      print(machine.succeed("nix store info"))
                      machine.succeed("test -f /run/current-system/bin/switch-to-configuration")
                      machine.succeed("nix store add-file $(mktemp)")
                      ro_paths = int(machine.succeed("ls /usr/nix/store | wc -l").strip())
                      rw_paths = int(machine.succeed("ls /overlay/upper | wc -l").strip())
                      merged_paths = int(machine.succeed("ls /nix/store | wc -l").strip())
                      print(f"{ro_paths=}, {rw_paths=}, {merged_paths=}")
                      assert ro_paths + rw_paths == merged_paths

                      gc_roots = machine.succeed("nix-store --gc --print-roots")
                      assert "/run/current-system" in gc_roots
                      assert "/run/booted-system" in gc_roots
                  else:
                      machine.fail("test -f /run/current-system/bin/switch-to-configuration")
                      machine.fail("nix store add-file $(mktemp)")


              with subtest("sysupdate"):
                  update_dir = "/var/lib/updates/${nodes.machine.networking.hostName}"
                  updateServer.copy_from_host("${nodes.machine.system.build.image}", update_dir)

                  print(updateServer.succeed(f"ls {update_dir}"))
                  current_usr = updateServer.succeed(f"ls {update_dir}/*${version}*.usr.raw.xz").strip()
                  current_usr_hash = updateServer.succeed(f"ls {update_dir}/*${version}*.usr-hash.raw.xz").strip()
                  current_uki = updateServer.succeed(f"ls {update_dir}/*${version}*.efi.xz").strip()

                  updateServer.succeed("mv {} {}".format(current_usr, current_usr.replace("${version}", "${newerVersion}", 1)))
                  updateServer.succeed("mv {} {}".format(current_usr_hash, current_usr_hash.replace("${version}", "${newerVersion}", 1)))
                  updateServer.succeed("mv {} {}".format(current_uki, current_uki.replace("${version}", "${newerVersion}", 1)))

                  gnupghome = updateServer.succeed("mktemp -d").strip()
                  updateServer.succeed(f"cp -R ${gpgKeyring}/* {gnupghome}")
                  updateServer.succeed(f"(cd {update_dir}; sha256sum * >SHA256SUMS)")
                  print(updateServer.succeed(f"cat {update_dir}/SHA256SUMS"))
                  print(updateServer.succeed(f"env GNUPGHOME={gnupghome} gpg --batch --sign --detach-sign --output {update_dir}/SHA256SUMS.gpg {update_dir}/SHA256SUMS"))

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
          lib.cartesianProduct {
            bootMethod = [
              "uefi"
              "uboot"
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
  // {
    image-installer = nixosTest {
      name = "image-installer";
      nodes = {
        inherit updateServer;

        machine = {
          imports = [
            baseConfig
            bootMethodConfig.uefi
          ];

          virtualisation.useDefaultFilesystems = false;
          virtualisation.diskSize = 4096;
          virtualisation.qemu.drives = [
            {
              name = "installer";
              file = ''"$INSTALLER_DISK_IMAGE"'';
              driveExtraOpts.cache = "writeback";
              driveExtraOpts.werror = "report";
              deviceExtraOpts.bootindex = "2";
              deviceExtraOpts.serial = "installer";
              deviceExtraOpts.id = "installer";
            }
          ];
        };
      };
      testScript =
        { nodes, ... }:
        ''
          import os
          import subprocess
          import tempfile

          ${unpackImage {
            config = nodes.machine;
            imageAttr = "diskInstaller";
            envVar = "INSTALLER_DISK_IMAGE";
          }}

          updateServer.wait_for_unit("multi-user.target")
          update_dir = "/var/lib/updates/${nodes.machine.networking.hostName}"
          updateServer.copy_from_host("${nodes.machine.system.build.image}", update_dir)

          machine.start(allow_reboot=True)
          machine.wait_for_console_text("reboot: Restarting system")
          machine.send_monitor_command("device_del installer")

          machine.wait_for_unit("multi-user.target")
        '';
    };
  }
)
