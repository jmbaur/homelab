{
  lib,
  inputs,
  nixosTest,
}:

let
  snakeoilKeys =
    lib.mapAttrs
      (_: keys: {
        privkey = lib.elemAt keys 0;
        pubkey = lib.elemAt keys 1;
      })
      {
        n1n2 = [
          "UIcKBiONUOEnuypvhi2J366dsvOgww2LvSvVeRTzjVU="
          "HaCYR2XdIETcv8bJK11T9zHUonUfe7UOFGHXy5eUOSY="
        ];
        n2n1 = [
          "8E1oRp82lXepy73tyYK2N/4VeRcJuZ50XmaRYanja10="
          "IH1BTFdXnPzN/bBUL4m4HjnDN3/IyQYYrIrDxRvWb2M="
        ];
        n2n3 = [
          "IBeQJaHLCUqbtlR/HZfXMQoVQ1WGOPhwnS3WOPwZKm0="
          "cmVkWO+cUTIeuSxuV+w8+DxIUqRor3KAvMXv+ohbczk="
        ];
        n3n2 = [
          "APH6M9vQmzhIMmBx9t1mH5ddQADHrwt4dkFUfe9qK1w="
          "5gqvG2uEyvlei1pOUnueE9enQr2FMfhPOT2rykRAFBE="
        ];
        n3n4 = [
          "yDPeh1z/32QZbLDimNtFSh2Ko22td6kr9xG8SnDcJU8="
          "D7Bp040zthoL716UasIcdU5ANkmuC/kbzF0+H4zHqm0="
        ];
        n4n3 = [
          "OAZgXqEgQ43RgJmBqNHi+84iruZjw5fGfOdhPI4XhH0="
          "4HkDUE0yJj0yIu1lceyME7l6UfWD+YOQXO/xdsV6F1k="
        ];
      };

  commonModule =
    { config, lib, ... }:
    {
      imports = [ inputs.self.nixosModules.default ];
      networking = {
        useNetworkd = true;
        useDHCP = false;
        interfaces = lib.mkForce (
          lib.listToAttrs (
            lib.imap1 (i: vlan: {
              name = "eth${toString i}";
              value = {
                ipv4.addresses = lib.mkForce [
                  {
                    address = "192.168.${toString vlan}.${
                      lib.replaceStrings [ "n" ] [ "" ] config.networking.hostName
                    }";
                    prefixLength = 24;
                  }
                ];
              };
            }) config.virtualisation.vlans
          )
        );
      };

      systemd.tmpfiles.settings."10-wg-keys" = lib.mapAttrs' (name: keys: {
        name = "/etc/wg-${lib.replaceStrings [ config.networking.hostName ] [ "" ] name}";
        value.f = {
          mode = "0640";
          user = "root";
          inherit (config.users.users.systemd-network) group;
          argument = keys.privkey;
        };
      }) (lib.filterAttrs (name: _: lib.substring 0 2 name == config.networking.hostName) snakeoilKeys);

      custom.wgNetwork = {
        ulaHextets = [
          64789
          49711
          54517
        ];
        nodes = lib.genAttrs [
          "n1"
          "n2"
          "n3"
          "n4"
        ] (_: { });
      };
    };
in

# n1-n2-n3-n4
nixosTest {
  name = "wg-network";
  nodes = {
    n1 = {
      imports = [ commonModule ];
      virtualisation.vlans = [ 1 ];
      custom.wgNetwork.nodes.n2 = {
        peer = true;
        initiate = true;
        endpointHost = "192.168.1.2";
        privateKey.file = "/etc/wg-n2";
        publicKey = snakeoilKeys.n2n1.pubkey;
      };
      custom.wgNetwork.nodes.n4.allowedTCPPorts = [ 8787 ];
      services.static-web-server = {
        enable = true;
        listen = "[::]:8787";
        root = "/run/current-system";
      };
    };
    n2 = {
      imports = [ commonModule ];
      virtualisation.vlans = [
        1
        2
      ];
      custom.wgNetwork.nodes.n1 = {
        peer = true;
        endpointHost = "192.168.1.1";
        privateKey.file = "/etc/wg-n1";
        publicKey = snakeoilKeys.n1n2.pubkey;
      };
      custom.wgNetwork.nodes.n3 = {
        peer = true;
        initiate = true;
        endpointHost = "192.168.2.3";
        privateKey.file = "/etc/wg-n3";
        publicKey = snakeoilKeys.n3n2.pubkey;
      };
    };
    n3 = {
      imports = [ commonModule ];
      virtualisation.vlans = [
        2
        3
      ];
      custom.wgNetwork.nodes.n2 = {
        peer = true;
        endpointHost = "192.168.2.2";
        privateKey.file = "/etc/wg-n2";
        publicKey = snakeoilKeys.n2n3.pubkey;
      };
      custom.wgNetwork.nodes.n4 = {
        peer = true;
        initiate = true;
        endpointHost = "192.168.3.4";
        privateKey.file = "/etc/wg-n4";
        publicKey = snakeoilKeys.n4n3.pubkey;
      };
    };
    n4 = {
      imports = [ commonModule ];
      virtualisation.vlans = [ 3 ];
      custom.wgNetwork.nodes.n3 = {
        peer = true;
        endpointHost = "192.168.3.3";
        privateKey.file = "/etc/wg-n3";
        publicKey = snakeoilKeys.n3n4.pubkey;
      };
    };
  };
  testScript =
    { nodes, ... }:
    ''
      start_all()

      for n in [n1, n2, n3, n4]:
          n.succeed("echo module wireguard +p > /sys/kernel/debug/dynamic_debug/control")
          n.wait_for_unit("network-online.target")
          print(n.succeed("wg"))

      # n1 can only reach n2
      n1.succeed("ping -c5 ${nodes.n1.custom.wgNetwork.nodes.n2.endpointHost}")
      n1.fail("ping -c5 ${nodes.n2.custom.wgNetwork.nodes.n3.endpointHost}")
      n1.fail("ping -c5 ${nodes.n3.custom.wgNetwork.nodes.n4.endpointHost}")

      # n2 can only reach n1 and n3
      n2.succeed("ping -c5 ${nodes.n2.custom.wgNetwork.nodes.n1.endpointHost}")
      n2.succeed("ping -c5 ${nodes.n2.custom.wgNetwork.nodes.n3.endpointHost}")
      n2.fail("ping -c5 ${nodes.n3.custom.wgNetwork.nodes.n4.endpointHost}")

      # n3 can only reach n2 and n4
      n3.succeed("ping -c5 ${nodes.n3.custom.wgNetwork.nodes.n2.endpointHost}")
      n3.succeed("ping -c5 ${nodes.n3.custom.wgNetwork.nodes.n4.endpointHost}")
      n3.fail("ping -c5 ${nodes.n2.custom.wgNetwork.nodes.n1.endpointHost}")

      # n4 can only reach n3
      n4.succeed("ping -c5 ${nodes.n4.custom.wgNetwork.nodes.n3.endpointHost}")
      n4.fail("ping -c5 ${nodes.n3.custom.wgNetwork.nodes.n2.endpointHost}")
      n4.fail("ping -c5 ${nodes.n2.custom.wgNetwork.nodes.n1.endpointHost}")

      # ensure wireguard peers are setup correctly
      n1.succeed("ping -c5 n2.internal")
      n1.succeed("ping -c5 n3.internal")
      n2.succeed("ping -c5 n1.internal")
      n3.succeed("ping -c5 n1.internal")
      n3.succeed("ping -c5 n4.internal")
      n4.succeed("ping -c5 n3.internal")

      # ensure every device can reach one another
      n1.succeed("ping -c5 n4.internal")
      n1.succeed("ping -c5 n3.internal")
      n2.succeed("ping -c5 n4.internal")
      n3.succeed("ping -c5 n1.internal")
      n4.succeed("ping -c5 n1.internal")
      n4.succeed("ping -c5 n2.internal")

      n2.fail("curl --max-time 1 n1.internal:8787")
      n3.fail("curl --max-time 1 n1.internal:8787")
      n4.succeed("curl --max-time 1 n1.internal:8787")
    '';
}
