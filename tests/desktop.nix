{ inputs, nixosTest }:

nixosTest {
  name = "desktop";
  nodes.machine = {
    imports = [ inputs.self.nixosModules.default ];
    virtualisation.memorySize = 4096;
    virtualisation.cores = 2;

    custom.desktop.enable = true;
  };
  testScript = ''
    # TODO(jared): this is just for driverInteractive usage right now
  '';
}
