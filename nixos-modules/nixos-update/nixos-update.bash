# shellcheck shell=bash

update_endpoint=$1

new_toplevel=$(curl \
	--location \
	--silent \
	--fail \
	--write-out "%{stderr}request for toplevel path returned with status %{http_code}\n" \
	--header "Accept: application/json" \
	"$update_endpoint" | jq --raw-output ".buildoutputs.out.path")

if [[ $(readlink --canonicalize /run/current-system) != "$new_toplevel" ]]; then
	nix-env --set --profile /nix/var/nix/profiles/system "$new_toplevel"

	# TODO(jared): We need to determine if the right thing to do is stc
	# "switch" or "boot".
	"${new_toplevel}/bin/switch-to-configuration" boot
fi
