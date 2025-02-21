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

	booted_toplevel_kernel="$(readlink --canonicalize-existing /run/booted-system/{initrd,kernel,kernel-modules})"
	booted_toplevel_params="$(cat /run/booted-system/kernel-params)"
	new_toplevel_kernel="$(readlink --canonicalize-existing "${new_toplevel}"/{initrd,kernel,kernel-modules})"
	new_toplevel_params="$(cat "${new_toplevel}"/kernel-params)"

	action=switch
	if [[ $booted_toplevel_kernel != "$new_toplevel_kernel" ]] || [[ $booted_toplevel_params != "$new_toplevel_params" ]]; then
		action=boot
	fi

	"${new_toplevel}/bin/switch-to-configuration" $action

	if [[ $action == "boot" ]]; then
		systemctl reboot
	fi
fi
