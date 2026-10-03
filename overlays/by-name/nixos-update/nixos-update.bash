# shellcheck shell=bash

declare argc_update_endpoint

declare -r profile=/nix/var/nix/profiles/system

# @arg action
# @option --update-endpoint

eval "$(argc --argc-eval "$0" "$@")"

function update() {
	new_toplevel=$(curl \
		--location \
		--silent \
		--fail \
		--write-out "%{stderr}request for toplevel path returned with status %{http_code}\n" \
		--header "Accept: application/json" \
		"$argc_update_endpoint" | jq --raw-output ".buildoutputs.out.path")

	if [[ $(readlink --canonicalize-existing /run/current-system) != "$new_toplevel" ]]; then
		nix-store --realise "$new_toplevel" >/dev/null

		# Never move to a configuration that is not newer than the running one,
		# e.g. after a manual deployment of something newer than what the build
		# host has.
		current_timestamp=$(jq --raw-output '."com.jmbaur.homelab.v1".timestamp // empty' /run/current-system/boot.json 2>/dev/null || true)
		new_timestamp=$(jq --raw-output '."com.jmbaur.homelab.v1".timestamp // empty' "${new_toplevel}/boot.json" 2>/dev/null || true)
		if [[ -n $current_timestamp ]] && [[ -n $new_timestamp ]]; then
			if ((new_timestamp <= current_timestamp)); then
				echo "Not updating to $new_toplevel, its timestamp ($new_timestamp) is not newer than the current system's ($current_timestamp)."
				return
			fi
		fi

		nix-env --set --profile $profile "$new_toplevel"

		booted_toplevel_kernel="$(readlink --canonicalize-existing /run/booted-system/{initrd,kernel,kernel-modules})"
		booted_toplevel_params="$(cat /run/booted-system/kernel-params)"
		new_toplevel_kernel="$(readlink --canonicalize-existing "${new_toplevel}"/{initrd,kernel,kernel-modules})"
		new_toplevel_params="$(cat "${new_toplevel}"/kernel-params)"

		switch_action=switch
		if [[ $booted_toplevel_kernel != "$new_toplevel_kernel" ]] || [[ $booted_toplevel_params != "$new_toplevel_params" ]]; then
			switch_action=boot
		fi

		"${new_toplevel}/bin/switch-to-configuration" $switch_action

		if [[ $switch_action == "boot" ]]; then
			echo "Setup $new_toplevel for next boot. Reboot to finish switch."
		fi
	fi
}

function reboot() {
	booted_toplevel_kernel="$(readlink --canonicalize-existing /run/booted-system/{initrd,kernel,kernel-modules})"
	booted_toplevel_params="$(cat /run/booted-system/kernel-params)"
	new_toplevel_kernel="$(readlink --canonicalize-existing $profile/{initrd,kernel,kernel-modules})"
	new_toplevel_params="$(cat $profile/kernel-params)"

	if [[ $booted_toplevel_kernel != "$new_toplevel_kernel" ]] || [[ $booted_toplevel_params != "$new_toplevel_params" ]]; then
		systemctl reboot
	fi
}

action=${argc_action:-}

case $action in
reboot | update) $action ;;
*)
	echo "unknown action \"$action\""
	exit 1
	;;
esac
