{ nixosTest, inputs }:

nixosTest {
  name = "uki-installer";

  nodes.machine = {
    imports = [ inputs.self.nixosModules.default ];

    custom.ukiInstaller.enable = true;

    virtualisation = {
      useBootLoader = true;
      useEFIBoot = true;
      useSecureBoot = true;
    };
  };

  testScript =
    { nodes, ... }:
    ''
      machine.start(allow_reboot=True)
      machine.wait_for_unit("default.target")
      assert 1 == int(machine.succeed("od --skip-bytes 4 --read-bytes 1 --output-duplicates --format dI --address-radix n /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c").strip())
      machine.succeed("! grep --silent secure-boot-enroll ${nodes.machine.boot.loader.efi.efiSysMountPoint}/loader/loader.conf")
    '';
}
