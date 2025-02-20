# shellcheck shell=bash

function copy() {
	if [[ -n $1 ]]; then
		file="$1"
	else
		file="-"
	fi

	out=$(mktemp)
	status=$(curl --silent --output "$out" --write-out "%{http_code}" --form "content=<$file" https://dpaste.com/api/v2/)

	case $status in
	201)
		sed 's,^.*/\(.*\)$,\1,' <"$out"
		;;
	*)
		printf "Failed to upload content\nStatus: %s\n" "$status"
		exit 1
		;;
	esac
}

function paste() {
	if [[ -z $1 ]]; then
		echo "missing ID"
		exit 1
	fi

	curl --silent --location "https://dpaste.com/${1}.txt"
	echo # dpaste strips newline from content, add it back
}

case ${1:-} in
copy | paste) $1 "${2:-}" ;;
*)
	echo 'invalid action (must be "copy" or "paste")'
	exit 1
	;;
esac
