# shellcheck shell=bash

declare kexec_jq

choice=${1:-}

if [[ -z $choice ]]; then
	declare -a choices

	while read -r system_closure; do
		choices+=("$system_closure")
	done < <(find /nix/var/nix/profiles -name 'system-*')

	choice=$(echo "${choices[@]}" | zf)
fi

if [[ -z $choice ]]; then
	exit 1
fi

eval "$(jq --raw-output --from-file "$kexec_jq" <"${choice}/boot.json")"

systemctl kexec
