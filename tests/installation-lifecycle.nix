{
  inputs,
  lib,
  nixosTest,
  qemu,
  zstd,
}:

nixosTest {
  name = "installation-lifecycle";
  nodes = {
    updateServer =
      { nodes, ... }:
      {
        virtualisation.vlans = [ 1 ];

        networking.firewall.allowedTCPPorts = [
          80
          5000
        ];

        systemd.tmpfiles.settings."10-sws-root"."/var/lib/updates".d = { };

        services.static-web-server = {
          enable = true;
          listen = "[::]:80";
          root = "/var/lib/updates";
        };

        services.harmonia = {
          enable = true;
          settings.bind = "[::]:5000";
        };

        system.extraDependencies = [
          nodes.machine.system.build.toplevel
          nodes.machine.system.build.foo-update.config.system.build.toplevel
        ];
      };

    machine =
      {
        config,
        lib,
        extendModules,
        ...
      }:
      {
        imports = [ inputs.self.nixosModules.default ];

        virtualisation.vlans = [ 1 ];

        virtualisation.useBootLoader = true;
        virtualisation.useEFIBoot = true;
        virtualisation.efi.keepVariables = false;
        virtualisation.directBoot.enable = false;
        virtualisation.mountHostNixStore = false;

        # Make the qemu-vm.nix module use what is found under
        # `config.fileSystems`.
        virtualisation.fileSystems = lib.mkForce { };
        virtualisation.useDefaultFilesystems = false;

        # We provide our own image for the installer.
        virtualisation.diskImage = null;

        boot.loader.timeout = 0;

        system.switch.enable = true;
        nix.settings.substituters = lib.mkForce [ "http://updateServer:5000?trusted=1" ];

        virtualisation.qemu.options = [
          "-drive index=1,if=virtio,id=nixos,format=qcow2,file=$NIXOS"
        ];

        custom.update = {
          enable = true;
          endpoint = "http://updateServer/${config.networking.hostName}";
        };

        custom.recovery = {
          enable = true;
          targetDisk = "/dev/vda";
          modules = [
            # TODO(jared): For some reason, this isn't propagated to the recovery
            # system configuration with `noUserModules.extendModules`.
            { virtualisation.test.nodeName = config.virtualisation.test.nodeName; }

            # OVMF does not work with the default repart sector size of 4096
            { image.repart.sectorSize = 512; }

            {
              virtualisation.fileSystems = lib.mkForce { };
              virtualisation.useDefaultFilesystems = false;
            }
          ];
        };

        # Provide something to update to.
        system.build.foo-update = extendModules {
          modules = [
            {
              environment.etc."foo".text = "foo";
            }
          ];
        };
      };
  };
  testScript =
    { nodes, ... }:
    # python
    ''
      import os
      import subprocess
      import tempfile

      def assert_boot_entry(filename: str):
          booted_entry = machine.succeed("iconv -f UTF-16 -t UTF-8 /sys/firmware/efi/efivars/LoaderEntrySelected-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f").strip('\x06').strip('\x00')
          if booted_entry != filename:
              raise Exception(f"booted from the wrong entry, expected {filename}, got {booted_entry}")

      with subtest("installation"):
          tmp_disk_image = tempfile.NamedTemporaryFile()

          with open(tmp_disk_image.name, "w") as outfile:
              subprocess.run([
                "${lib.getExe zstd}",
                "--force",
                "--decompress",
                "--stdout",
                "${nodes.machine.system.build.recovery.config.system.build.image}/recovery.raw.zst",
              ], stdout=outfile)

          os.environ["USB_STICK"] = tmp_disk_image.name

          updateServer.wait_for_unit("multi-user.target")
          updateServer.succeed("echo ${nodes.machine.system.build.toplevel} >/var/lib/updates/${nodes.machine.networking.hostName}")

          os.environ["QEMU_OPTS"] = f"-drive index=2,if=virtio,id=installer,format=raw,file={tmp_disk_image.name}"

          tmp_nixos_disk_image = tempfile.NamedTemporaryFile()
          os.environ["NIXOS"] = tmp_nixos_disk_image.name
          subprocess.run(["${lib.getExe' qemu "qemu-img"}", "create", "-f", "qcow2", tmp_nixos_disk_image.name, "4096M"])
          machine.wait_for_unit("nixos-recovery.service")
          machine.wait_for_shutdown() # a reboot will occur after installation succeeds
          os.environ["QEMU_OPTS"] = ""

          machine.start(allow_reboot=True)
          machine.wait_for_unit("multi-user.target")
          assert_boot_entry("nixos-generation-1.conf")
          assert "${nodes.machine.system.build.toplevel}" == machine.succeed("readlink --canonicalize /run/current-system").strip()

      with subtest("update"):
          updateServer.succeed("echo ${nodes.machine.system.build.foo-update.config.system.build.toplevel} >/var/lib/updates/${nodes.machine.networking.hostName}")
          machine.succeed("systemctl start nixos-update.service")
          machine.reboot()
          assert "foo" == machine.succeed("cat /etc/foo").strip()
    '';
}