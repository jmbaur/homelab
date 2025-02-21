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

	new_kernel_version=$(nix derivation show "${new_toplevel}/kernel" | jq --raw-output 'to_entries[0].value.env.version')
	current_kernel_version=$(nix derivation show "/run/current-system/kernel" | jq --raw-output 'to_entries[0].value.env.version')

	action=switch
	if [[ $new_kernel_version != "$current_kernel_version" ]]; then
		action=boot
	fi

	"${new_toplevel}/bin/switch-to-configuration" $action

	if [[ $action == "boot" ]]; then
		systemctl reboot
	fi
fi
