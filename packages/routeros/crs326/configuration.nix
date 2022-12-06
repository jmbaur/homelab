{ lib, writeText, inventoryFile, ... }:
let
  unusedVlanId = 99;
  inventory = lib.importJSON inventoryFile;
  configuration = {
    name = "CRS326-24G-2S+";
    commands = [
      "/interface bridge add admin-mac=18:FD:74:32:D7:B7 auto-mac=no ingress-filtering=no name=bridge vlan-filtering=yes"
      "/interface vlan add interface=bridge name=mgmt vlan-id=${toString inventory.networks.mgmt.id}"
      "/interface lte apn set [ find default=yes ] ip-type=ipv4 use-network-apn=no"
      "/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik"
      "/port set 0 name=serial0"
      "/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=ether1 pvid=${toString unusedVlanId}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether2 pvid=${toString inventory.networks.mgmt.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether3 pvid=${toString inventory.networks.mgmt.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether4 pvid=${toString inventory.networks.mgmt.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether5 pvid=${toString inventory.networks.mgmt.id}"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether6"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether7"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether8"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether9"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=no interface=ether10 pvid=${toString inventory.networks.work.id}"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether11"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether12"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether13"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether14"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether15 pvid=${toString inventory.networks.work.id}"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether16"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether17 pvid=${toString inventory.networks.iot.id}"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether18"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether19 pvid=${toString inventory.networks.trusted.id}"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether20"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether21"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether22"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether23 pvid=${toString inventory.networks.mgmt.id}"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=ether24"
      "/interface bridge port add bridge=bridge disabled=yes ingress-filtering=no interface=sfp-sfpplus1"
      "/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=sfp-sfpplus2 pvid=${toString unusedVlanId}"
      "/ip settings set max-neighbor-entries=8192"
      "/interface bridge vlan add bridge=bridge tagged=ether1,bridge,sfp-sfpplus2 untagged=ether2,ether3,ether4,ether5,ether23 vlan-ids=${toString inventory.networks.mgmt.id}"
      "/interface bridge vlan add bridge=bridge tagged=ether1,sfp-sfpplus2 untagged=ether19 vlan-ids=${toString inventory.networks.trusted.id}"
      "/interface bridge vlan add bridge=bridge tagged=ether1,sfp-sfpplus2 untagged=ether17 vlan-ids=${toString inventory.networks.iot.id}"
      "/interface bridge vlan add bridge=bridge tagged=ether1,sfp-sfpplus2 untagged=ether10,ether15 vlan-ids=${toString inventory.networks.work.id}"
      "/interface ovpn-server server set auth=sha1,md5"
      "/ip address add address=${inventory.networks.mgmt.hosts.switch0.ipv4}/${toString inventory.networks.mgmt._ipv4Cidr} interface=${inventory.networks.mgmt.name} network=${inventory.networks.mgmt._networkIPv4}"
      "/ip dns set servers=${inventory.networks.mgmt.hosts.artichoke.ipv4}"
      "/ip route add disabled=no dst-address=0.0.0.0/0 gateway=${inventory.networks.mgmt.hosts.artichoke.ipv4}"
      "/ipv6 route add dst-address=::/0 gateway=${inventory.networks.mgmt.hosts.artichoke.ipv6.ula}%${inventory.networks.mgmt.name}"
      "/ip service set telnet disabled=yes"
      "/ip service set ftp disabled=yes"
      "/ip service set www disabled=yes"
      "/ip service set winbox disabled=yes"
      "/ip service set api-ssl disabled=yes"
      "/ipv6 address add address=${inventory.networks.mgmt.hosts.switch0.ipv6.ula} advertise=no interface=${inventory.networks.mgmt.name}"
      "/system clock set time-zone-name=America/Los_Angeles"
      "/system identity set name=${inventory.networks.mgmt.hosts.switch0.name}"
      "/system routerboard settings set boot-os=router-os"
    ];
  };
in
writeText "${configuration.name}.rsc" ''
  ${lib.concatStringsSep "\n" configuration.commands}
''
