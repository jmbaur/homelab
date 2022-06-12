{ lib, ... }:
{ inventory, secrets, ... }: {
  name = "CRS305-1G-4S+";
  commands =
    let
      gateway = toString inventory.mgmt.hosts.broccoli.ipv4;
    in
    [
      "/interface bridge add admin-mac=DC:2C:6E:A4:CA:CC auto-mac=no ingress-filtering=no name=bridge vlan-filtering=yes"
      "/interface vlan add interface=bridge name=${inventory.mgmt.name} vlan-id=${toString inventory.mgmt.id}"
      "/interface lte apn set [ find default=yes ] ip-type=ipv4 use-network-apn=no"
      "/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik"
      "/port set 0 name=serial0"
      "/routing bgp template set default disabled=no output.network=bgp-networks"
      "/routing ospf instance add disabled=no name=default-v2"
      "/routing ospf instance add disabled=no name=default-v3 version=3"
      "/routing ospf area add disabled=yes instance=default-v2 name=backbone-v2"
      "/routing ospf area add disabled=yes instance=default-v3 name=backbone-v3"
      "/interface bridge port add bridge=bridge ingress-filtering=no interface=ether1 pvid=${toString inventory.mgmt.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=sfp-sfpplus1"
      "/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=sfp-sfpplus2"
      "/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-vlan-tagged interface=sfp-sfpplus3"
      "/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=sfp-sfpplus4"
      "/ip settings set max-neighbor-entries=8192"
      "/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus4 vlan-ids=${lib.concatMapStringsSep "," toString (with inventory; [pubwan.id publan.id trusted.id iot.id work.id])}"
      "/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus4,bridge untagged=ether1 vlan-ids=${toString inventory.mgmt.id}"
      "/interface ovpn-server server set auth=sha1,md5"
    ] ++
    (map
      (addr: "/ip address add address=${addr}/${toString inventory.mgmt.ipv4Cidr} interface=${inventory.mgmt.name} network=${inventory.mgmt.networkIPv4}")
      inventory.mgmt.hosts.switch0.ipv4)
    ++ [
      "/ip dns set servers=${gateway}"
      "/ip route add disabled=no dst-address=0.0.0.0/0 gateway=${gateway}"
      "/ip service set telnet disabled=yes"
      "/ip service set ftp disabled=yes"
      "/ip service set www disabled=yes"
      "/ip service set winbox disabled=yes"
      "/ip service set api-ssl disabled=yes"
      "/system clock set time-zone-name=America/Los_Angeles"
      "/system identity set name=${inventory.mgmt.hosts.switch0.name}"
      "/system routerboard settings set boot-os=router-os"
    ];
}
