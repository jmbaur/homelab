# jun/11/2022 17:07:51 by RouterOS 7.3.1
# software id = U4IB-HZ8I
#
# model = CRS305-1G-4S+
/interface bridge add admin-mac=DC:2C:6E:A4:CA:CC auto-mac=no comment=defconf ingress-filtering=no name=bridge vlan-filtering=yes
/interface vlan add interface=bridge name=mgmt vlan-id=88
/interface lte apn set [ find default=yes ] ip-type=ipv4 use-network-apn=no
/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik
/port set 0 name=serial0
/routing bgp template set default disabled=no output.network=bgp-networks
/routing ospf instance add disabled=no name=default-v2
/routing ospf instance add disabled=no name=default-v3 version=3
/routing ospf area add disabled=yes instance=default-v2 name=backbone-v2
/routing ospf area add disabled=yes instance=default-v3 name=backbone-v3
/interface bridge port add bridge=bridge comment=defconf ingress-filtering=no interface=ether1 pvid=88
/interface bridge port add bridge=bridge comment=defconf frame-types=admit-only-vlan-tagged interface=sfp-sfpplus1
/interface bridge port add bridge=bridge comment=defconf frame-types=admit-only-vlan-tagged interface=sfp-sfpplus2
/interface bridge port add bridge=bridge comment=defconf disabled=yes frame-types=admit-only-vlan-tagged interface=sfp-sfpplus3
/interface bridge port add bridge=bridge comment=defconf frame-types=admit-only-vlan-tagged interface=sfp-sfpplus4
/ip settings set max-neighbor-entries=8192
/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus4 vlan-ids=10,20,30,40,50
/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus4,bridge untagged=ether1 vlan-ids=88
/interface ovpn-server server set auth=sha1,md5
/ip address add address=192.168.88.2/24 interface=mgmt network=192.168.88.0
/ip dns set servers=192.168.88.1
/ip route add disabled=no dst-address=0.0.0.0/0 gateway=192.168.88.1
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set api-ssl disabled=yes
/system clock set time-zone-name=America/Los_Angeles
/system identity set name=switch0
/system routerboard settings set boot-os=router-os
