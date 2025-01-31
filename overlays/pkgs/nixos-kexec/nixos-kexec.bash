# shellcheck shell=bash

declare kexec_jq

choice=${1:-}

if [[ -z $choice ]]; then
	choice=$(find /nix/var/nix/profiles -name 'system-*' | zf)
fi

if [[ -z $choice ]]; then
	exit 1
fi

eval "$(jq --raw-output --from-file "$kexec_jq" <"${choice}/boot.json")"

systemctl kexec
