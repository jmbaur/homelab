# shellcheck shell=bash

IFS=: read -r pubkey dnsname <<<"$1"

echo "using pubkey $pubkey"
echo "using dns name $dnsname"

while true; do
	for record_type in "AAAA" "A"; do
		answer=$(dig +nocmd +noall +answer +ttlid "$record_type" "$dnsname")

		# dig returns an empty response if there is no record for the requested record type
		if [[ $answer == "" ]]; then
			continue 1
		fi

		read -r ttl addr < <(echo "$answer" | awk '{ print $2, $5 }')
		if ! ip route get "$addr" >/dev/null 2>&1; then
			if [[ ${DEBUG:-0} == "1" ]]; then
				echo "address $addr not reachable"
			fi
			continue 1
		fi

		if wg show wg0 endpoints | grep --silent "$pubkey.*$addr.*"; then
			if [[ ${DEBUG:-0} == "1" ]]; then
				echo "peer endpoint is up to date"
				echo "sleeping ${ttl}s until cache is invalid"
			fi
			sleep "$(("$ttl" + 1))"
			continue 2
		else
			new_endpoint=
			if [[ $record_type == "AAAA" ]]; then
				new_endpoint="[$addr]:51820"
			else
				new_endpoint="$addr:51820"
			fi

			echo "peer endpoint is out of date"
			echo "setting endpoint for $pubkey to $new_endpoint"
			wg set wg0 peer "$pubkey" endpoint "$new_endpoint"
			break 1
		fi
	done
done
