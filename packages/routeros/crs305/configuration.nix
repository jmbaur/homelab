{ lib, writeText, inventoryFile, ... }:
let
  inventory = lib.importJSON inventoryFile;
  gateway = inventory.networks.mgmt.hosts.artichoke.ipv4;
  configuration = {
    name = "CRS305-1G-4S+";
    commands = [
      "/interface bridge add admin-mac=DC:2C:6E:A4:CA:CC auto-mac=no name=bridge vlan-filtering=yes"
      "/interface vlan add interface=bridge name=${inventory.networks.mgmt.name} vlan-id=${toString inventory.networks.mgmt.id}"
      "/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik"
      "/port set 0 name=serial0"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether1 pvid=${toString inventory.networks.mgmt.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=sfp-sfpplus1 pvid=${toString inventory.networks.work.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=sfp-sfpplus2 pvid=${toString inventory.networks.mgmt.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=sfp-sfpplus3 pvid=${toString inventory.networks.trusted.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=sfp-sfpplus4"
      "/interface bridge vlan add bridge=bridge tagged=bridge,sfp-sfpplus4 untagged=ether1,sfp-sfpplus3 vlan-ids=${toString inventory.networks.mgmt.id}"
      "/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus4 untagged=sfp-sfpplus1 vlan-ids=${toString inventory.networks.work.id}"
      "/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus4 untagged=sfp-sfpplus2 vlan-ids=${toString inventory.networks.trusted.id}"
      "/ip address add address=${inventory.networks.mgmt.hosts.switch0.ipv4}/${toString inventory.networks.mgmt.ipv4Cidr} interface=${inventory.networks.mgmt.name} network=${inventory.networks.mgmt.networkIPv4}"
      "/ip dns set servers=${gateway}"
      "/ip route add dst-address=0.0.0.0/0 gateway=${gateway}"
      "/ip service set telnet disabled=yes"
      "/ip service set ftp disabled=yes"
      "/ip service set www disabled=yes"
      "/ip service set winbox disabled=yes"
      "/ip service set api-ssl disabled=yes"
      "/system clock set time-zone-name=America/Los_Angeles"
      "/system identity set name=${inventory.networks.mgmt.hosts.switch0.name}"
      "/system routerboard settings set boot-os=router-os"
    ];
  };
in
writeText "${configuration.name}.rsc" ''
  ${lib.concatStringsSep "\n" configuration.commands}
''

# # oct/03/2022 09:37:58 by RouterOS 7.5
# # software id = U4IB-HZ8I
# #
# # model = CRS305-1G-4S+
# # serial number = F0B10F4AA6BD
# /interface bridge add admin-mac=DC:2C:6E:A4:CA:CC auto-mac=no comment=defconf name=bridge
# /interface vlan add interface=bridge name=mgmt vlan-id=10
# /interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik
# /port set 0 name=serial0
# /interface bridge port add bridge=bridge comment=defconf interface=ether1 pvid=10
# /interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus1 pvid=30
# /interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus2 pvid=50
# /interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus3
# /interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus4
# /interface bridge vlan add bridge=bridge tagged=sfp-sfpplus4 untagged=ether1 vlan-ids=10
# /interface bridge vlan add bridge=bridge tagged=sfp-sfpplus4 untagged=sfp-sfpplus1 vlan-ids=30
# /interface bridge vlan add bridge=bridge tagged=sfp-sfpplus4 untagged=sfp-sfpplus2 vlan-ids=50
# /ip address add address=192.168.88.1/24 comment=defconf interface=bridge network=192.168.88.0
# /ip address add address=172.16.10.3/24 interface=mgmt network=172.16.10.0
# /ip dns set servers=172.16.10.1
# /ip route add dst-address=0.0.0.0/0 gateway=172.16.10.1
# /system clock set time-zone-name=America/Los_Angeles
# /system identity set name=switch1
# /system routerboard settings set boot-os=router-os
