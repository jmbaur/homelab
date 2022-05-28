# may/27/2022 17:03:46 by RouterOS 6.49.6
# software id = 22YL-M8PX
#
# model = CRS326-24G-2S+
/interface bridge
add name=bridge vlan-filtering=yes
/interface vlan
add interface=bridge name=mgmt vlan-id=88
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/interface bridge port
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether1 pvid=88
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether2 pvid=88
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether3 pvid=88
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether4 pvid=88
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether5 pvid=30
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether6 pvid=30
add bridge=bridge frame-types=admit-only-vlan-tagged ingress-filtering=yes interface=ether7
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether8
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether9
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether10
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether11
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether12
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether13
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether14
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether15
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether16
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether17
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether18
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether19
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether20
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether21
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether22
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether23
add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged ingress-filtering=yes interface=ether24
add bridge=bridge frame-types=admit-only-vlan-tagged ingress-filtering=yes interface=sfp-sfpplus1
add bridge=bridge frame-types=admit-only-vlan-tagged ingress-filtering=yes interface=sfp-sfpplus2
/ip neighbor discovery-settings
set discover-interface-list=!dynamic
/interface bridge vlan
add bridge=bridge tagged=sfp-sfpplus1,ether7 vlan-ids=40
add bridge=bridge tagged=sfp-sfpplus1,sfp-sfpplus2,ether7,bridge untagged=ether1,ether2,ether3,ether4 vlan-ids=88
add bridge=bridge tagged=sfp-sfpplus1,sfp-sfpplus2,ether7 untagged=ether5,ether6 vlan-ids=30
add bridge=bridge tagged=sfp-sfpplus1,ether7 untagged=ether8 vlan-ids=50
/ip address
add address=192.168.88.3/24 interface=mgmt network=192.168.88.0
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
set name=switch1
/system routerboard settings
set boot-os=router-os
