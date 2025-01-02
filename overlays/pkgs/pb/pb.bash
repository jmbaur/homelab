# shellcheck shell=bash

out=$(mktemp)
trap 'rm $out' EXIT

status=$(curl --silent --output "$out" --write-out "%{http_code}" --data-binary @- https://paste.rs/)

case $status in
201)
	printf "%s\n" "$(cat "$out")"
	;;
206)
	printf "Failed to upload all content.\n%s\n" "$(cat "$out")"
	;;
*)
	printf "Failed to upload content\nStatus: %s\n" "$status"
	exit 1
	;;
esac
