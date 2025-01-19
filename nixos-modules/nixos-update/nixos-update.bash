# shellcheck shell=bash

update_endpoint=${1:-}

if [[ -z $update_endpoint ]]; then
	echo "No update endpoint specified"
	exit 1
fi

new_toplevel=$(curl --silent --fail "$update_endpoint")

if [[ $(readlink --canonicalize /run/current-system) != "$new_toplevel" ]]; then
	nix-store --realise "$new_toplevel"

	nix-env --set --profile /nix/var/nix/profiles/system "$new_toplevel"

	# TODO(jared): We need to determine if the right thing to do is stc
	# "switch" or "boot".
	"${new_toplevel}/bin/switch-to-configuration" boot
fi
