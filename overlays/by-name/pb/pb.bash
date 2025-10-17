# shellcheck shell=bash

out=$(mktemp)

status=$(curl --silent --output "$out" --write-out "%{http_code}" --data-binary @/dev/stdin https://paste.rs)

case $status in
201)
	printf "%s\n" "$(cat "$out")" | tee /dev/stderr | qrencode --type=ansiutf8
	;;
*)
	printf "Failed to upload content\nStatus: %s\n" "$status"
	exit 1
	;;
esac
