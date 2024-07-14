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
        n1 = [
          "mLQi1DtGD8Ex+/lvMrLB9AJOuZzZgCzAPt6dZtDMFGM="
          "MVShh+4bZX9xIWOR5g7bGDNRF4pRNtRjUI3YY4WLyXU="
        ];
        n2 = [
          "eMWNAIwcDF3LyF9TTtgcTYbRzwK0rQQvtsMIpHOqSF8="
          "3JOw0POjZKH2NAUrQDZrUsBFSZuljK29OrvUKZwWY3s="
        ];
        n3 = [
          "APiN4e2gT7DhOfvYCRZOEAyLAzxibFRBUSop7RgOlWw="
          "dDVrHByjiMXcoO318Hyd+H9jYPyDa9o+rZGUJV9XU20="
        ];
        n4 = [
          "YJGeU4Bw9lDkMqV/3VzoZlOTpRqnFIID0l4XsA9RfGs="
          "ody3JmGBHJDFDr75KGIk2p89HzG1jOA+SXygtgb4Clc="
        ];
      };

  commonModule =
    { config, lib, ... }:
    {
      imports = [ inputs.self.nixosModules.default ];
      networking = {
        useNetworkd = true;
        useDHCP = false;
        firewall.enable = false;
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

      systemd.tmpfiles.settings."10-wg-privkey"."/etc/wg.privkey".f = {
        mode = "0640";
        user = "root";
        inherit (config.users.users.systemd-network) group;
        argument = snakeoilKeys.${config.networking.hostName}.privkey;
      };

      custom.wgNetwork = {
        privateKey.file = "/etc/wg.privkey";
        ulaHextets = [
          64789
          49711
          54517
        ];
        nodes = lib.genAttrs (lib.attrNames snakeoilKeys) (host: {
          inherit (snakeoilKeys.${host}) pubkey;
        });
      };
    };
in

# n2-n1-n3-n4
nixosTest {
  name = "wg-network";
  nodes = {
    n1 = {
      imports = [ commonModule ];
      virtualisation.vlans = [
        1
        2
      ];
      custom.wgNetwork.nodes.n2 = {
        enable = true;
        hostname = "192.168.1.2";
      };
      custom.wgNetwork.nodes.n3 = {
        enable = true;
        hostname = "192.168.2.3";
      };
    };
    n2 = {
      imports = [ commonModule ];
      virtualisation.vlans = [ 1 ];
      custom.wgNetwork.nodes.n1 = {
        enable = true;
        hostname = "192.168.1.1";
      };
    };
    n3 = {
      imports = [ commonModule ];
      virtualisation.vlans = [
        2
        3
      ];
      custom.wgNetwork.nodes.n1 = {
        enable = true;
        hostname = "192.168.2.1";
      };
      custom.wgNetwork.nodes.n4 = {
        enable = true;
        hostname = "192.168.3.4";
      };
    };
    n4 = {
      imports = [ commonModule ];
      virtualisation.vlans = [ 3 ];
      custom.wgNetwork.nodes.n3 = {
        enable = true;
        hostname = "192.168.3.3";
      };
    };
  };
  testScript =
    { nodes, ... }:
    assert nodes.n1.services.babeld.enable;
    assert !nodes.n2.services.babeld.enable;
    assert nodes.n3.services.babeld.enable;
    assert !nodes.n4.services.babeld.enable;
    ''
      n1.wait_for_unit("network-online.target")
      n2.wait_for_unit("network-online.target")
      n3.wait_for_unit("network-online.target")
      n4.wait_for_unit("network-online.target")

      print(n1.succeed("wg"))
      print(n2.succeed("wg"))
      print(n3.succeed("wg"))
      print(n4.succeed("wg"))

      # n1 can only directly reach n2 and n3
      n1.succeed("ping -c5 ${nodes.n1.custom.wgNetwork.nodes.n2.hostname}")
      n1.succeed("ping -c5 ${nodes.n1.custom.wgNetwork.nodes.n3.hostname}")
      n1.fail("ping -c5 ${nodes.n3.custom.wgNetwork.nodes.n4.hostname}")

      # n2 can only reach n1
      n2.succeed("ping -c5 ${nodes.n2.custom.wgNetwork.nodes.n1.hostname}")
      n2.fail("ping -c5 ${nodes.n1.custom.wgNetwork.nodes.n3.hostname}")
      n2.fail("ping -c5 ${nodes.n3.custom.wgNetwork.nodes.n4.hostname}")

      # n1 can only directly reach n1 and n4
      n3.succeed("ping -c5 ${nodes.n3.custom.wgNetwork.nodes.n1.hostname}")
      n3.succeed("ping -c5 ${nodes.n3.custom.wgNetwork.nodes.n4.hostname}")
      n3.fail("ping -c5 ${nodes.n1.custom.wgNetwork.nodes.n2.hostname}")

      # ensure wireguard peers are setup correctly
      n1.succeed("ping -c5 n2.internal")
      n1.succeed("ping -c5 n3.internal")
      n2.succeed("ping -c5 n1.internal")
      n3.succeed("ping -c5 n1.internal")
      n3.succeed("ping -c5 n4.internal")
      n4.succeed("ping -c5 n3.internal")
    '';
}
