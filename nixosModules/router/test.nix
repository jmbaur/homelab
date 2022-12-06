{ nixosTest, module, ... }:
nixosTest {
  name = "router";
  nodes.router = { ... }: {
    imports = [ module ];
    custom.inventory = {
      networks = {
        n1 = {
          guaPrefix = "2000:1::/64";
          ulaPrefix = "fc00:1::/64";
          v4Prefix = "192.168.1.0/24";
          policy = { };
          hosts = { h1n1.id = 1; };
        };
        n2 = {
          guaPrefix = "2000:2::/64";
          ulaPrefix = "fc00:2::/64";
          v4Prefix = "192.168.2.0/24";
          policy = { n1 = { allowAll = true; }; };
          hosts = { h1n2.id = 1; };
        };
      };
    };
  };
  testScript = builtins.readFile ./test.py;
}
