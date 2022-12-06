{ nixosTest, module, ... }:
nixosTest {
  name = "router";
  nodes.router = { ... }: {
    imports = [ module ];
    custom.inventory = {
      v4Prefix = "192.168.0.0/16";
      v6UlaPrefix = "fc00::/48";
      v6GuaPrefix = "2000::/48";
      networks = {
        n1 = {
          id = 1;
          hosts.h1n1.id = 1;
        };
        n2 = {
          id = 2;
          policy.n1.allowAll = true;
          hosts.h1n2.id = 1;
        };
      };
    };
  };
  testScript = builtins.readFile ./test.py;
}
