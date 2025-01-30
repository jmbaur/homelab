# shellcheck shell=bash

hostname=$1
port=$2

ipv6_link_local_address=$(dig +short AAAA "$hostname" | grep '^fe80')
dev=$(ip -j -6 neighbor show | jq --raw-output --arg ip "$ipv6_link_local_address" '.[] | select(.dst == $ip) | .dev')

nc "${ipv6_link_local_address}%${dev}" "$port"
