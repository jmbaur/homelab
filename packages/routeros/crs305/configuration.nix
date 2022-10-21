{ lib, writeText, inventoryFile, ... }:
let
  unusedVlanId = 99;
  inventory = lib.importJSON inventoryFile;
  configuration = {
    name = "CRS305-1G-4S+";
    commands = [
      "/interface bridge add admin-mac=DC:2C:6E:A4:CA:CC auto-mac=no name=bridge vlan-filtering=yes"
      "/interface vlan add interface=bridge name=${inventory.networks.mgmt.name} vlan-id=${toString inventory.networks.mgmt.id}"
      "interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik"
      "/ip hotspot profile set [ find default=yes ] html-directory=hotspot"
      "/port set 0 name=serial0"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether1 pvid=${toString inventory.networks.trusted.id}"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=sfp-sfpplus1"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=sfp-sfpplus2"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=sfp-sfpplus3"
      "/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=sfp-sfpplus4 pvid=${toString unusedVlanId}"
      "/interface bridge vlan add bridge=bridge tagged=bridge,sfp-sfpplus4 vlan-ids=${toString inventory.networks.mgmt.id}"
      "/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus4 untagged=ether1 vlan-ids=${toString inventory.networks.trusted.id}"
      "/ip address add address=${inventory.networks.mgmt.hosts.switch1.ipv4}/${toString inventory.networks.mgmt.ipv4Cidr} interface=${inventory.networks.mgmt.name} network=${inventory.networks.mgmt.networkIPv4}"
      "/ip dns set servers=${inventory.networks.mgmt.hosts.artichoke.ipv4}"
      "/ip route add dst-address=0.0.0.0/0 gateway=${inventory.networks.mgmt.hosts.artichoke.ipv4}"
      "/ipv6 route add dst-address=::/0 gateway=${inventory.networks.mgmt.hosts.artichoke.ipv6.ula}%${inventory.networks.mgmt.name}"
      "/ip service set telnet disabled=yes"
      "/ip service set ftp disabled=yes"
      "/ip service set www disabled=yes"
      "/ip service set winbox disabled=yes"
      "/ip service set api-ssl disabled=yes"
      "/ipv6 address add address=${inventory.networks.mgmt.hosts.switch1.ipv6.ula} advertise=no interface=${inventory.networks.mgmt.name}"
      "/system clock set time-zone-name=America/Los_Angeles"
      "/system identity set name=${inventory.networks.mgmt.hosts.switch1.name}"
      "/system routerboard settings set boot-os=router-os"
    ];
  };
in
writeText "${configuration.name}.rsc" ''
  ${lib.concatStringsSep "\n" configuration.commands}
''
