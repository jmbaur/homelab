# vim: ft=make

help:
	@just --list

switch:
	nixos-rebuild switch -L --flake .# --use-remote-sudo

build:
	#!/usr/bin/env bash
	nix build -L \
		.\#ipwatch \
		.\#linux_cn913x \
		.\#runner-nix \
		.\#webauthn-tiny

setup_pam_u2f:
	pamu2fcfg -opam://homelab

setup_yubikey:
	ykman openpgp keys set-touch sig cached-fixed
