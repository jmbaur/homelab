# jun/11/2022 17:09:04 by RouterOS 7.3.1
# software id = 22YL-M8PX
#
# model = CRS326-24G-2S+
/interface bridge add ingress-filtering=no name=bridge vlan-filtering=yes
/interface vlan add interface=bridge name=mgmt vlan-id=88
/interface lte apn set [ find default=yes ] ip-type=ipv4 use-network-apn=no
/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik
/port set 0 name=serial0
/routing bgp template set default disabled=no output.network=bgp-networks
/routing ospf instance add disabled=no name=default-v2
/routing ospf area add disabled=yes instance=default-v2 name=backbone-v2
/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether1 pvid=88
/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether2 pvid=88
/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether3 pvid=88
/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether4 pvid=88
/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether5 pvid=30
/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether6 pvid=30
/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=ether7
/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=ether8 pvid=50
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether9
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether10
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether11
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether12
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether13
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether14
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether15
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether16
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether17
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether18
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether19
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether20
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether21
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether22
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether23
/interface bridge port add bridge=bridge disabled=yes frame-types=admit-only-untagged-and-priority-tagged interface=ether24
/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=sfp-sfpplus1
/interface bridge port add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged interface=sfp-sfpplus2 pvid=30
/ip neighbor discovery-settings set discover-interface-list=!dynamic
/ip settings set max-neighbor-entries=8192
/ipv6 settings set disable-ipv6=yes
/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus1,ether7 vlan-ids=40
/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus1,ether7,bridge untagged=ether1,ether2,ether3,ether4 vlan-ids=88
/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus1,ether7 untagged=ether5,ether6,sfp-sfpplus2 vlan-ids=30
/interface bridge vlan add bridge=bridge tagged=sfp-sfpplus1,ether7 untagged=ether8 vlan-ids=50
/interface ovpn-server server set auth=sha1,md5
/ip address add address=192.168.88.3/24 interface=mgmt network=192.168.88.0
/ip dns set servers=192.168.88.1
/ip route add disabled=no dst-address=0.0.0.0/0 gateway=192.168.88.1
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set winbox disabled=yes
/ip service set api-ssl disabled=yes
/system clock set time-zone-name=America/Los_Angeles
/system identity set name=switch1
/system routerboard settings set boot-os=router-os
