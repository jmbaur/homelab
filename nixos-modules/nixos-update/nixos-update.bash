# shellcheck shell=bash

update_endpoint=$1

read -ra keys < <(nix --experimental-features nix-command config show trusted-public-keys)

new_toplevel=$(curl --silent --fail "$update_endpoint")
new_toplevel_sig=$(curl --silent --fail "${update_endpoint}.sig")
nix-key verify <(echo -n "$new_toplevel") <(echo -n "$new_toplevel_sig") "${keys[@]}"

if [[ $(readlink --canonicalize /run/current-system) != "$new_toplevel" ]]; then
	nix-store --realise "$new_toplevel"

	nix-env --set --profile /nix/var/nix/profiles/system "$new_toplevel"

	# TODO(jared): We need to determine if the right thing to do is stc
	# "switch" or "boot".
	"${new_toplevel}/bin/switch-to-configuration" boot
fi
