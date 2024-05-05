{ nixosTest, inputs }:

nixosTest {
  name = "normal-user";

  nodes.machine =
    { config, pkgs, ... }:
    {
      imports = [ inputs.self.nixosModules.default ];
      custom.normalUser.enable = true;
      virtualisation.emptyDiskImages = [ 1024 ];
      virtualisation.fileSystems."/home" = {
        device = "/dev/vdb";
        fsType = "ext4";
        # autoFormat = true; # doesn't work in stage-1 ?
        neededForBoot = true;
      };
      fileSystems."/home" = config.virtualisation.fileSystems."/home";
      boot.initrd.postDeviceCommands = ''
        ${pkgs.e2fsprogs}/bin/mkfs.ext4 /dev/vdb
      '';
    };

  testScript = ''
    def login_as_riker(pwd):
        machine.wait_until_tty_matches("1", "login: ")
        machine.send_chars("riker\n")
        machine.wait_until_tty_matches("1", "Password: ")
        machine.send_chars(f"{pwd}\n")
        machine.wait_until_tty_matches("1", "riker\@machine")

    def logout():
        machine.send_chars("logout\n")
        machine.wait_until_tty_matches("1", "login: ")

    machine.wait_for_unit("multi-user.target")

    with subtest("fscrypt setup successfully"):
        machine.succeed("test -d /home/riker")
        assert "\"/home/riker\" is encrypted with fscrypt" in machine.succeed("fscrypt status /home/riker")

    with subtest("create file"):
        login_as_riker("NumberOne")
        machine.send_chars("touch foo\n")
        machine.wait_until_succeeds("test -f /home/riker/foo")
        logout()
        machine.wait_until_fails("test -f /home/riker/foo")

    with subtest("change password"):
        login_as_riker("NumberOne")
        machine.send_chars("passwd\n")
        machine.wait_until_tty_matches("1", "Current password: ")
        machine.send_chars("NumberOne\n")
        machine.wait_until_tty_matches("1", "New password: ")
        machine.send_chars("foobar\n")
        machine.wait_until_tty_matches("1", "Retype new password: ")
        machine.send_chars("foobar\n")
        machine.wait_until_tty_matches("1", "password updated successfully")
        protector_id = machine.succeed("ls /.fscrypt/protectors").strip()
        machine.send_chars(f"fscrypt metadata change-passphrase --protector=/:{protector_id}\n")
        machine.wait_until_tty_matches("1", "Enter old login passphrase for riker: ")
        machine.send_chars("NumberOne\n")
        machine.wait_until_tty_matches("1", "Enter new login passphrase for riker: ")
        machine.send_chars("foobar\n")
        machine.wait_until_tty_matches("1", "successfully changed")
        logout()

    with subtest("file created before password creation still exists"):
        login_as_riker("foobar")
        machine.succeed("test -f /home/riker/foo")
        logout()
        machine.wait_until_fails("test -f /home/riker/foo")
  '';
}
