{ nixosTest, module, ... }:
nixosTest {
  name = "router";
  nodes.router = { ... }: {
    imports = [ module ];
    custom.inventory = {
      networks = {
        n1 = { id = 1; policy = { }; };
        n2 = { id = 2; policy = { n1 = { allowAll = true; }; }; };
      };
    };
  };
  testScript = builtins.readFile ./test.py;
}
