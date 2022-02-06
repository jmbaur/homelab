:global addVlan do={
	/interface/vlan {
		:local found [find name=$vlanName]
		:if ($found) do={
			set numbers=$found name=$vlanName interface=$iface vlan-id=$vlanId mtu=$vlanMtu
		} else={
			add name=$vlanName interface=$iface vlan-id=$vlanId mtu=$vlanMtu
		}
		# not allowed to have duplicate vlans with the same name, so don't have
		# to worry about removing any here
	}
}

:global removeVlansNotIn do={
	/interface/vlan {
		:foreach n in=[find] do={
			:local name [get value-name=name number=$n];
			:local found [:find $list $name -1];
			:if ($found < 0) do={
				remove $name
			}
		}
	}
}

$addVlan vlanName="trusted" iface="combo1" vlanId=10 vlanMtu=1500
$addVlan vlanName="iot" iface="combo1" vlanId=20 vlanMtu=1500
$addVlan vlanName="guest" iface="combo1" vlanId=30 vlanMtu=1500
$removeVlansNotIn list=({"trusted";"iot";"guest";})


:global setIpAddress do={
	/ip/address {
		:local found [find interface=$iface]
			:if ($found) do={
				set number=$found interface=$iface address=$addr
			} else={
				add interface=$iface address=$addr
			}
		remove [find interface=$iface address!=$addr]
	}
}

$setIpAddress iface="ether7" addr=192.168.88.1/24
$setIpAddress iface="trusted" addr=192.168.10.1/24
$setIpAddress iface="iot" addr=192.168.20.1/24
$setIpAddress iface="guest" addr=192.168.30.1/24
