# vim: ft=make

help:
	@just --list

init:
	mkdir -p $out

clean: init
	rm -rf {{justfile_directory()}}/result*
	rm -rf $out/*

switch:
	nixos-rebuild switch -L --use-remote-sudo --flake .#

build:
	nix build -L --accept-flake-config \
		.\#cicada \
		.\#coredns-utils \
		.\#flarectl \
		.\#flashrom-cros \
		.\#flashrom-dasharo \
		.\#git-get \
		.\#gobar \
		.\#gosee \
		.\#ipwatch \
		.\#neovim \
		.\#neovim-all-languages \
		.\#pd-notify \
		.\#pomo \
		.\#runner-nix \
		.\#webauthn-tiny \
		.\#wezterm-jmbaur \
		.\#xremap \
		.\#yamlfmt

update:
	#!/usr/bin/env bash
	cd {{justfile_directory()}}/overlays
	export NIX_PATH="nixpkgs=$(nix flake prefetch nixpkgs --json | jq --raw-output '.storePath')"
	for drv in $(nix eval --impure --expr "builtins.attrNames (import ./out-of-tree.nix {})" --json | jq -r ".[]"); do
		nix-update --file ./out-of-tree.nix $drv
	done

setup_pam_u2f:
	pamu2fcfg -opam://homelab

setup_yubikey:
	ykman openpgp keys set-touch sig cached-fixed
