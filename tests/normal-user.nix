{ nixosTest, inputs }:

nixosTest {
  name = "normal-user";

  nodes.machine =
    { config, pkgs, ... }:
    {
      imports = [ inputs.self.nixosModules.default ];
      custom.normalUser.enable = true;
      virtualisation.qemu.options = [ "-nographic" ];
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
        machine.succeed("test -d /home/riker.homedir")
        # assert "\"/home/riker\" is encrypted with fscrypt" in machine.succeed("fscrypt status /home/riker")

    with subtest("create file"):
        login_as_riker("NumberOne")
        machine.succeed("touch foo")
        machine.succeed("test -f foo")
        logout()

    # with subtest("change password"):
    #     machine.succeed("su - riker -c '(echo NumberOne; echo foobar; echo foobar) | passwd'")
    #     protector_id = machine.succeed("ls /.fscrypt/protectors").strip()
    #     machine.succeed(f"su - riker -c '(echo NumberOne; echo foobar) | fscrypt metadata change-passphrase --protector=/:{protector_id}'")

    # with subtest("file created before password creation still exists"):
    #     login_as_riker("foobar")
    #     machine.succeed("test -f foo")
    #     logout()
  '';
}
