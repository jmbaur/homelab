{ writeShellScriptBin, jq, sops }:
let
  configScript = writeShellScriptBin "configScript" ''
    data=$(cat $1)

    cat << EOF
    # jun/11/2022 17:10:44 by RouterOS 7.3.1
    # software id = TD07-GRS2
    #
    # model = RBcAPGi-5acD2nD
    # serial number = E2820F048DAF
    /interface bridge add admin-mac=DC:2C:6E:0D:FE:6F auto-mac=no comment=defconf ingress-filtering=no name=bridge vlan-filtering=yes
    /interface wireless set [ find default-name=wlan1 ] ssid=MikroTik
    /interface vlan add interface=bridge name=mgmt vlan-id=88
    /interface lte apn set [ find default=yes ] ip-type=ipv4 use-network-apn=no
    /interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik
    /interface wireless security-profiles add authentication-types=wpa2-psk mode=dynamic-keys name=iot supplicant-identity=MikroTik wpa2-pre-shared-key=$(${jq}/bin/jq ".iot.password" <<< $data)
    /interface wireless security-profiles add authentication-types=wpa2-psk mode=dynamic-keys name=trusted supplicant-identity=MikroTik wpa2-pre-shared-key=$(${jq}/bin/jq '.trusted.password' <<< $data)
    /interface wireless security-profiles add authentication-types=wpa2-psk mode=dynamic-keys name=work supplicant-identity=MikroTik wpa2-pre-shared-key=$(${jq}/bin/jq '.work.password' <<< $data)
    /interface wireless set [ find default-name=wlan2 ] band=5ghz-a/n/ac channel-width=20/40/80mhz-XXXX disabled=no distance=indoors frequency=auto installation=indoor mode=ap-bridge security-profile=trusted ssid=$(${jq}/bin/jq '.trusted.ssid' <<< $data) vlan-id=30 vlan-mode=use-tag wireless-protocol=802.11
    /interface wireless add disabled=no mac-address=DE:2C:6E:0D:FE:71 master-interface=wlan2 name=wlan3 security-profile=iot ssid=$(${jq}/bin/jq '.iot.ssid' <<< $data) vlan-id=40 vlan-mode=use-tag
    /interface wireless add disabled=no mac-address=DE:2C:6E:0D:FE:72 master-interface=wlan2 name=wlan4 security-profile=work ssid=$(${jq}/bin/jq '.work.ssid' <<< $data) vlan-id=50 vlan-mode=use-tag
    /routing bgp template set default disabled=no output.network=bgp-networks
    /routing ospf instance add disabled=no name=default-v2
    /routing ospf area add disabled=yes instance=default-v2 name=backbone-v2
    /interface bridge port add bridge=bridge comment=defconf ingress-filtering=no interface=ether2
    /interface bridge port add bridge=bridge comment=defconf frame-types=admit-only-vlan-tagged interface=wlan2 pvid=30
    /interface bridge port add bridge=bridge ingress-filtering=no interface=ether1
    /interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=wlan3 pvid=40
    /interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=wlan4 pvid=50
    /ip neighbor discovery-settings set discover-interface-list=none
    /ip settings set max-neighbor-entries=8192
    /ipv6 settings set disable-ipv6=yes max-neighbor-entries=8192
    /interface bridge vlan add bridge=bridge tagged=bridge,ether1 vlan-ids=88
    /interface bridge vlan add bridge=bridge tagged=ether1,wlan2 vlan-ids=30
    /interface bridge vlan add bridge=bridge tagged=wlan3,ether1 vlan-ids=40
    /interface bridge vlan add bridge=bridge tagged=ether1,wlan4 vlan-ids=50
    /interface ovpn-server server set auth=sha1,md5
    /ip address add address=192.168.88.4/24 interface=mgmt network=192.168.88.0
    /ip dns set servers=192.168.88.1
    /ip dns static add address=192.168.88.1 comment=defconf name=router.lan
    /ip route add disabled=no dst-address=0.0.0.0/0 gateway=192.168.88.1 pref-src=192.168.88.4
    /ip service set telnet disabled=yes
    /ip service set ftp disabled=yes
    /ip service set www disabled=yes
    /ip service set winbox disabled=yes
    /ip service set api-ssl disabled=yes
    /system clock set time-zone-name=America/Los_Angeles
    /system identity set name=ap0
    /system leds settings set all-leds-off=immediate
    /system routerboard mode-button set enabled=yes on-event=dark-mode
    /system script add comment=defconf dont-require-permissions=no name=dark-mode owner=*sys policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\r\
        \n   :if ([system leds settings get all-leds-off] = \"never\") do={\r\
        \n     /system leds settings set all-leds-off=immediate \r\
        \n   } else={\r\
        \n     /system leds settings set all-leds-off=never \r\
        \n   }\r\
        \n "
    /tool mac-server set allowed-interface-list=none
    /tool mac-server mac-winbox set allowed-interface-list=none

    EOF
  '';
in
writeShellScriptBin "cap_ac" ''
  ${sops}/bin/sops exec-file --output-type=json ${../secrets.yaml} '${configScript}/bin/configScript {}'
''
