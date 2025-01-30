# shellcheck shell=bash

hostname=$1
port=$2

ipv6_link_local_address=$(dig +short AAAA "$hostname" | grep '^fe80')
dev=$(ip -j -6 route get "$ipv6_link_local_address" | jq --raw-output '.[0].dev')

nc "${ipv6_link_local_address}%${dev}" "$port"
