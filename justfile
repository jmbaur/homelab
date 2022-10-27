help:
	@just --list

build:
	#!/usr/bin/env bash
	nix build -L \
		.\#ipwatch \
		.\#linux_cn913x \
		.\#runner-nix \
		.\#webauthn-tiny

update:
	#!/usr/bin/env bash
	for input in $(nix eval -f ./flake.nix inputs --json | jq --raw-output "keys[]"); do
		if [[ "$input" != "homelab-private" ]]; then
			nix flake lock --update-input $input
		fi
	done

setup_pam_u2f:
	pamu2fcfg -opam://homelab

setup_yubikey:
	ykman openpgp keys set-touch sig cached-fixed
