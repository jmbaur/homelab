{ path, inventoryFile, secretFile, ... }:
with import path { };
let
  secrets = lib.importJSON secretFile;
  inventory = lib.importJSON inventoryFile;
  gateway = inventory.networks.mgmt.hosts.broccoli.ipv4;
  configuration = {
    name = "RBcAPGi-5acD2nD";
    commands = [
      "/interface bridge add admin-mac=DC:2C:6E:0D:FE:6F auto-mac=no ingress-filtering=no name=bridge vlan-filtering=yes"
      "/interface wireless set [ find default-name=wlan1 ] ssid=MikroTik"
      "/interface vlan add interface=bridge name=${inventory.networks.mgmt.name} vlan-id=${toString inventory.networks.mgmt.id}"
      "/interface lte apn set [ find default=yes ] ip-type=ipv4 use-network-apn=no"
      "/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik"
      "/interface wireless security-profiles add authentication-types=wpa2-psk mode=dynamic-keys name=${inventory.networks.iot.name} supplicant-identity=MikroTik wpa2-pre-shared-key=${secrets.iot.password}"
      "/interface wireless security-profiles add authentication-types=wpa2-psk mode=dynamic-keys name=${inventory.networks.trusted.name} supplicant-identity=MikroTik wpa2-pre-shared-key=${secrets.trusted.password}"
      "/interface wireless security-profiles add authentication-types=wpa2-psk mode=dynamic-keys name=${inventory.networks.work.name} supplicant-identity=MikroTik wpa2-pre-shared-key=${secrets.work.password}"
      "/interface wireless set [ find default-name=wlan2 ] band=5ghz-a/n/ac channel-width=20/40/80mhz-XXXX disabled=no distance=indoors frequency=auto installation=indoor mode=ap-bridge security-profile=${inventory.networks.trusted.name} ssid=\"${secrets.trusted.ssid}\" vlan-id=${toString inventory.networks.trusted.id} vlan-mode=use-tag wireless-protocol=802.11"
      "/interface wireless add disabled=no mac-address=DE:2C:6E:0D:FE:71 master-interface=wlan2 name=wlan3 security-profile=${inventory.networks.iot.name} ssid=\"${secrets.iot.ssid}\" vlan-id=${toString inventory.networks.iot.id} vlan-mode=use-tag"
      "/interface wireless add disabled=no mac-address=DE:2C:6E:0D:FE:72 master-interface=wlan2 name=wlan4 security-profile=${inventory.networks.work.name} ssid=\"${secrets.work.ssid}\" vlan-id=${toString inventory.networks.work.id} vlan-mode=use-tag"
      "/routing bgp template set default disabled=no output.network=bgp-networks"
      "/routing ospf instance add disabled=no name=default-v2"
      "/routing ospf area add disabled=yes instance=default-v2 name=backbone-v2"
      "/interface bridge port add bridge=bridge ingress-filtering=no interface=ether2"
      "/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=wlan2 pvid=${toString inventory.networks.trusted.id}"
      "/interface bridge port add bridge=bridge ingress-filtering=no interface=ether1"
      "/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=wlan3 pvid=${toString inventory.networks.iot.id}"
      "/interface bridge port add bridge=bridge frame-types=admit-only-vlan-tagged interface=wlan4 pvid=${toString inventory.networks.work.id}"
      "/ip neighbor discovery-settings set discover-interface-list=none"
      "/ip settings set max-neighbor-entries=8192"
      "/ipv6 settings set disable-ipv6=yes max-neighbor-entries=8192"
      "/interface bridge vlan add bridge=bridge tagged=bridge,ether1 vlan-ids=${toString inventory.networks.mgmt.id}"
      "/interface bridge vlan add bridge=bridge tagged=ether1,wlan2 vlan-ids=${toString inventory.networks.trusted.id}"
      "/interface bridge vlan add bridge=bridge tagged=wlan3,ether1 vlan-ids=${toString inventory.networks.iot.id}"
      "/interface bridge vlan add bridge=bridge tagged=ether1,wlan4 vlan-ids=${toString inventory.networks.work.id}"
      "/interface ovpn-server server set auth=sha1,md5"
      "/ip address add address=${inventory.networks.mgmt.hosts.ap0.ipv4}/${toString inventory.networks.mgmt.ipv4Cidr} interface=${inventory.networks.mgmt.name} network=${inventory.networks.mgmt.networkIPv4}"
      "/ip dns set servers=${gateway}"
      "/ip route add disabled=no dst-address=0.0.0.0/0 gateway=${gateway} pref-src=${inventory.networks.mgmt.hosts.ap0.ipv4}"
      "/ip service set telnet disabled=yes"
      "/ip service set ftp disabled=yes"
      "/ip service set www disabled=yes"
      "/ip service set winbox disabled=yes"
      "/ip service set api-ssl disabled=yes"
      "/system clock set time-zone-name=America/Los_Angeles"
      "/system identity set name=${inventory.networks.mgmt.hosts.ap0.name}"
      "/system leds settings set all-leds-off=immediate"
      "/system routerboard mode-button set enabled=yes on-event=dark-mode"
      ''/system script add dont-require-permissions=no name=dark-mode owner=*sys policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\r\
          \n   :if ([system leds settings get all-leds-off] = \"never\") do={\r\
          \n     /system leds settings set all-leds-off=immediate \r\
          \n   } else={\r\
          \n     /system leds settings set all-leds-off=never \r\
          \n   }\r\
          \n "''
      "/tool mac-server set allowed-interface-list=none"
      "/tool mac-server mac-winbox set allowed-interface-list=none"
    ];
  };
in
writeText "${configuration.name}.rsc" ''
  ${lib.concatStringsSep "\n" configuration.commands}
''
