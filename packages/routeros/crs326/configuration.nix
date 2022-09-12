{ lib, writeText, inventoryFile, ... }:
let
  inventory = lib.importJSON inventoryFile;
  gateway = inventory.networks.mgmt.hosts.artichoke.ipv4;
  configuration = {
    name = "CRS326-24G-2S+";
    commands = [
      "/interface bridge add ingress-filtering=no name=bridge vlan-filtering=yes"
      "/interface vlan add interface=bridge name=${inventory.networks.mgmt.name} vlan-id=${toString inventory.networks.mgmt.id}"
      "/interface lte apn set [ find default=yes ] ip-type=ipv4 use-network-apn=no"
      "/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik"
      "/port set 0 name=serial0"
      "/routing bgp template set default disabled=no output.network=bgp-networks"
      "/routing ospf instance add disabled=no name=default-v2"
      "/routing ospf area add disabled=yes instance=default-v2 name=backbone-v2"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether1 pvid=${toString inventory.networks.mgmt.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether2 pvid=${toString inventory.networks.mgmt.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether3 pvid=${toString inventory.networks.mgmt.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether4 pvid=${toString inventory.networks.mgmt.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether5 pvid=${toString inventory.networks.trusted.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether6 pvid=${toString inventory.networks.trusted.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=ether7"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether8 pvid=${toString inventory.networks.work.id}"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether9"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether10"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether11"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether12"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether13"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether14"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether15"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether16"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether17"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether18"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether19"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether20"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether21"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether22"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether23"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether24"
      "/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=sfp-sfpplus1"
      "/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=sfp-sfpplus2 pvid=${toString inventory.networks.trusted.id}"
      "/ip neighbor discovery-settings set discover-interface-list=!dynamic"
      "/ip settings set max-neighbor-entries=8192"
      "/ipv6 settings set disable-ipv6=yes"
      "/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus1,ether7 vlan-ids=${toString inventory.networks.iot.id}"
      "/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus1,ether7,bridge untagged=ether1,ether2,ether3,ether4 vlan-ids=${toString inventory.networks.mgmt.id}"
      "/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus1,ether7 untagged=ether5,ether6,sfp-sfpplus2 vlan-ids=${toString inventory.networks.trusted.id}"
      "/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus1,ether7 untagged=ether8 vlan-ids=${toString inventory.networks.work.id}"
      "/interface ovpn-server server set auth=sha1,md5"
      "/ip address add address=${inventory.networks.mgmt.hosts.switch1.ipv4}/${toString inventory.networks.mgmt.ipv4Cidr} interface=${inventory.networks.mgmt.name} network=${inventory.networks.mgmt.networkIPv4}"
      "/ip dns set servers=${gateway}"
      "/ip route add disabled=no dst-address=0.0.0.0/0 gateway=${gateway}"
      "/ip service set telnet disabled=yes"
      "/ip service set ftp disabled=yes"
      "/ip service set www disabled=yes"
      "/ip service set winbox disabled=yes"
      "/ip service set api-ssl disabled=yes"
      "/system clock set time-zone-name=America/Los_Angeles"
      "/system identity set name=${inventory.networks.mgmt.hosts.switch1.name}"
      "/system routerboard settings set boot-os=router-os"
    ];
  };
in
writeText "${configuration.name}.rsc" ''
  ${lib.concatStringsSep "\n" configuration.commands}
''
