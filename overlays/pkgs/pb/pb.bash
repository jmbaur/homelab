# shellcheck shell=bash

out=$(mktemp)
trap 'rm $out' EXIT

status=$(curl --silent --output "$out" --write-out "%{http_code}" --form "content=<-" https://dpaste.com/api/v2/)

case $status in
201)
	echo "$(cat "$out").txt" # append .txt to get URL we can curl later
	;;
*)
	printf "Failed to upload content\nStatus: %s\n" "$status"
	exit 1
	;;
esac
