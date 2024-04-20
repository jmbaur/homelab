{ nixosTest, inputs }:

nixosTest {
  name = "normal-user";

  nodes.machine = {
    imports = [ inputs.self.nixosModules.default ];
    custom.normalUser.enable = true;
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
        machine.succeed("touch foo")
        machine.succeed("test -f foo")
        logout()

    with subtest("change password"):
        machine.succeed("su - riker -c '(echo NumberOne; echo foobar; echo foobar) | passwd'")
        protector_id = machine.succeed("ls /.fscrypt/protectors").strip()
        machine.succeed(f"su - riker -c '(echo NumberOne; echo foobar) | fscrypt metadata change-passphrase --protector=/:{protector_id}'")

    with subtest("file created before password creation still exists"):
        login_as_riker("foobar")
        machine.succeed("test -f foo")
        logout()
  '';
}
