{
  lib,
  testers,
  inputs,
}:

testers.runNixOSTest {
  name = "nixos-kexec";

  extraBaseModules.imports = [ inputs.self.nixosModules.default ];

  node.pkgs = lib.mkForce null;

  nodes.machine =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.nixos-kexec ];
      specialisation.hello.configuration = {
        environment.systemPackages = [ pkgs.hello ];
      };
    };

  testScript = ''
    machine.fail("hello")
    machine.succeed("nixos-kexec /run/current-system/specialisation/hello")
    machine.connected = False
    machine.connect()
    machine.succeed("hello")
  '';
}
