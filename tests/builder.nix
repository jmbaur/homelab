{
  inputs,
  nixosTest,
}:

nixosTest {
  name = "builder";
  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ inputs.self.nixosModules.default ];
      custom.builder.builds.emptyFile.build.drvPath = pkgs.emptyFile.drvPath;
    };
  testScript = ''
    machine.succeed("systemctl start build@emptyFile.service")
    machine.succeed("systemctl start build@emptyFile.service")
  '';
}
