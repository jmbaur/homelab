# may/10/2022 15:08:28 by RouterOS 6.49.6
# software id = U4IB-HZ8I
#
# model = CRS305-1G-4S+
/interface bridge
add admin-mac=DC:2C:6E:A4:CA:CC auto-mac=no comment=defconf name=bridge vlan-filtering=yes
/interface vlan
add interface=bridge name=mgmt vlan-id=88
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/interface bridge port
add bridge=bridge comment=defconf interface=ether1 pvid=88
add bridge=bridge comment=defconf frame-types=admit-only-vlan-tagged ingress-filtering=yes interface=sfp-sfpplus1
add bridge=bridge comment=defconf frame-types=admit-only-vlan-tagged ingress-filtering=yes interface=sfp-sfpplus2
add bridge=bridge comment=defconf disabled=yes frame-types=admit-only-vlan-tagged ingress-filtering=yes interface=sfp-sfpplus3
add bridge=bridge comment=defconf frame-types=admit-only-vlan-tagged ingress-filtering=yes interface=sfp-sfpplus4
/interface bridge vlan
add bridge=bridge tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus4 vlan-ids=10,20,30,40,50
add bridge=bridge tagged=sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus4,bridge untagged=ether1 vlan-ids=88
/ip address
add address=192.168.88.2/24 interface=mgmt network=192.168.88.0
/ip dns
set servers=192.168.88.1
/ip route
add distance=1 gateway=192.168.88.1
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set winbox disabled=yes
set api-ssl disabled=yes
/system clock
set time-zone-name=America/Los_Angeles
/system identity
set name=switch0
/system routerboard settings
set boot-os=router-os
