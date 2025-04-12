# shellcheck shell=bash

declare kexec_jq argc_append argc_config

# @option --append   Extra kernel parameters to append to the declared NixOS config kernel parameter
# @arg config        NixOS config to boot

eval "$(argc --argc-eval "$0" "$@")"

# echo append: $argc_append
# echo append: $argc_config

choice=${argc_config:-}

if [[ -z $choice ]]; then
	choice=$(
		find /nix/var/nix/profiles -name 'system-*' | tac |
			(
				mapfile -t stdin </dev/stdin
				if [[ ${#stdin[@]} -eq 1 ]]; then printf "%s" "${stdin[0]}"; else printf "%s\n" "${stdin[@]}" | fzy; fi
			)
	)
fi

if [[ -z $choice ]]; then
	exit 1
fi

# Ensure our appended params begin with an empty space, as to not combine with
# the last kernel param in the selected nixos closure.
if [[ -n ${argc_append:-} ]]; then
	argc_append=" ${argc_append}"
fi

eval "$(jq --raw-output --arg append "${argc_append:-}" --from-file "$kexec_jq" <"${choice}/boot.json")"

systemctl kexec
