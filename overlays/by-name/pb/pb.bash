# shellcheck shell=bash

out=$(mktemp)

status=$(curl --silent --output "$out" --write-out "%{http_code}" -F"content=<-" -F"lexer=_text" -F"format=url" https://dpaste.org/api/)

case $status in
200)
	printf "%s/raw\n" "$(cat "$out")" | tee /dev/stderr | qrencode --type=ansiutf8
	;;
*)
	printf "Failed to upload content\nStatus: %s\n" "$status"
	exit 1
	;;
esac
