# shellcheck shell=bash

hostname=$1
port=$2

# select link local address
ipv6_link_local_address=$(resolvectl query --json=short --type=AAAA "$hostname" |
	jq --raw-output 'select(.address[0] == 254 and .address[1] == 128) | "printf \"%x%x::%x%x:%x%x:%x%x:%x%x\" \([254, 128] + .address[8:] | join(" "))"' | $BASH)

mapfile -t interfaces < <(ip -j -6 neighbor show | jq --raw-output --arg ip "$ipv6_link_local_address" '.[] | select(.dst == $ip) | .dev')

declare -a interface=()

for iface in "${interfaces[@]}"; do
	route_metric=$(ip -j -6 route get "$ipv6_link_local_address" iif "$iface" | jq --raw-output '.[0].metric')
	if [[ $route_metric == "null" ]]; then
		continue
	fi

	if [[ ${#interface[@]} -eq 0 ]] || [[ ${interface[0]} -gt $route_metric ]]; then
		interface=("$route_metric" "$iface")
	fi
done

if [[ ${#interface[@]} -eq 0 ]]; then
	exit 1
fi

nc "${ipv6_link_local_address}%${interface[1]}" "$port"
