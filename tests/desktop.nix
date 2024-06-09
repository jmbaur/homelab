{ inputs, nixosTest }:

nixosTest {
  name = "desktop";
  nodes.machine = {
    imports = [ inputs.self.nixosModules.default ];

    virtualisation.graphics = true;

    # So the desktop isn't super sluggish
    virtualisation.memorySize = 4096;
    virtualisation.cores = 2;

    # So we can do user creation
    virtualisation.qemu.consoles = [ "tty0" ];

    custom.desktop.enable = true;
  };
  testScript = ''
    raise NotImplementedError()
  '';
}
