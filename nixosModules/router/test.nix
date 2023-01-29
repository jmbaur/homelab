{ nixosTest, module, ... }:
nixosTest {
  name = "router";
  nodes.router = { ... }: {
    imports = [ module ];
    networking.heTunnelBroker = {
      # TODO(jared): setup a GRE tunnel node to handle these
      serverIPv4Address = "127.0.0.1";
      serverIPv6Address = "::1";
      clientIPv6Address = "::2";
    };
    router.inventory = {
      v4Prefix = "192.168.0.0/16";
      v6UlaPrefix = "fc00::/48";
      v6GuaPrefix = "2000::/48";
      wan = "wan";
      networks = {
        n1 = {
          id = 1;
          physical = { enable = true; interface = "n1"; };
          hosts.h1.id = 1;
        };
        n2 = {
          id = 2;
          physical = { enable = true; interface = "n2"; };
          policy.n1.allowAll = true;
          hosts.h1.id = 1;
        };
      };
    };
  };
  testScript = builtins.readFile ./test.py;
}
