{ writeShellScriptBin, jq, sops }:
let
  configScript = writeShellScriptBin "configScript" ''
    data=$(cat $1)

    cat << EOF
    # jun/11/2022 15:57:38 by RouterOS 6.49.6
    # software id = TD07-GRS2
    #
    # model = RBcAPGi-5acD2nD
    /interface bridge
    add admin-mac=DC:2C:6E:0D:FE:6F auto-mac=no comment=defconf name=bridge vlan-filtering=yes
    /interface wireless
    set [ find default-name=wlan1 ] ssid=MikroTik
    /interface vlan
    add interface=bridge name=mgmt vlan-id=88
    /interface wireless security-profiles
    set [ find default=yes ] supplicant-identity=MikroTik
    add authentication-types=wpa2-psk mode=dynamic-keys name=iot supplicant-identity=MikroTik wpa2-pre-shared-key=$(${jq}/bin/jq ".iot.password" <<< $data)
    add authentication-types=wpa2-psk mode=dynamic-keys name=trusted supplicant-identity=MikroTik wpa2-pre-shared-key=$(${jq}/bin/jq '.trusted.password' <<< $data)
    add authentication-types=wpa2-psk mode=dynamic-keys name=work supplicant-identity=MikroTik wpa2-pre-shared-key=$(${jq}/bin/jq '.work.password' <<< $data)
    /interface wireless
    set [ find default-name=wlan2 ] band=5ghz-a/n/ac channel-width=20/40/80mhz-XXXX disabled=no distance=indoors frequency=auto installation=indoor mode=ap-bridge \
        security-profile=trusted ssid=$(${jq}/bin/jq '.trusted.ssid' <<< $data) vlan-id=30 vlan-mode=use-tag wireless-protocol=802.11
    add disabled=no mac-address=DE:2C:6E:0D:FE:71 master-interface=wlan2 name=wlan3 security-profile=iot ssid=$(${jq}/bin/jq '.iot.ssid' <<< $data) vlan-id=40 vlan-mode=use-tag
    add disabled=no mac-address=DE:2C:6E:0D:FE:72 master-interface=wlan2 name=wlan4 security-profile=work ssid=$(${jq}/bin/jq '.work.ssid' <<< $data) vlan-id=50 vlan-mode=use-tag
    /interface bridge port
    add bridge=bridge comment=defconf interface=ether2
    add bridge=bridge comment=defconf frame-types=admit-only-vlan-tagged ingress-filtering=yes interface=wlan2 pvid=30
    add bridge=bridge interface=ether1
    add bridge=bridge frame-types=admit-only-vlan-tagged ingress-filtering=yes interface=wlan3 pvid=40
    add bridge=bridge frame-types=admit-only-vlan-tagged ingress-filtering=yes interface=wlan4 pvid=50
    /ip neighbor discovery-settings
    set discover-interface-list=none
    /interface bridge vlan
    add bridge=bridge tagged=bridge,ether1 vlan-ids=88
    add bridge=bridge tagged=ether1,wlan2 vlan-ids=30
    add bridge=bridge tagged=wlan3,ether1 vlan-ids=40
    add bridge=bridge tagged=ether1,wlan4 vlan-ids=50
    /ip address
    add address=192.168.88.4/24 interface=mgmt network=192.168.88.0
    /ip dns
    set servers=192.168.88.1
    /ip dns static
    add address=192.168.88.1 comment=defconf name=router.lan
    /ip route
    add distance=1 gateway=192.168.88.1 pref-src=192.168.88.4
    /ip service
    set telnet disabled=yes
    set ftp disabled=yes
    set www disabled=yes
    set winbox disabled=yes
    set api-ssl disabled=yes
    /system clock
    set time-zone-name=America/Los_Angeles
    /system identity
    set name=ap0
    /system leds settings
    set all-leds-off=immediate
    /system routerboard mode-button
    set enabled=yes on-event=dark-mode
    /system script
    add comment=defconf dont-require-permissions=no name=dark-mode owner=*sys policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\r\
        \\n   :if ([system leds settings get all-leds-off] = \"never\") do={\r\
        \\n     /system leds settings set all-leds-off=immediate \r\
        \\n   } else={\r\
        \\n     /system leds settings set all-leds-off=never \r\
        \\n   }\r\
        \\n "
    /tool mac-server
    set allowed-interface-list=none
    /tool mac-server mac-winbox
    set allowed-interface-list=none
    EOF
  '';
in
writeShellScriptBin "cap_ac" ''
  ${sops}/bin/sops exec-file --output-type=json ${../secrets.yaml} '${configScript}/bin/configScript {}'
''
