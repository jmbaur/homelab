# vim: ft=make

help:
	@just --list

switch:
	home-manager switch --flake .#jared

build:
	#!/usr/bin/env bash
	nix build -L \
		.\#cicada \
		.\#coredns-utils \
		.\#flarectl \
		.\#git-get \
		.\#gobar \
		.\#gosee \
		.\#ipwatch \
		.\#linux_cn913x \
		.\#neovim \
		.\#pd-notify \
		.\#runner-nix \
		.\#webauthn-tiny \
		.\#xremap \
		.\#yamlfmt \
		.\#zf

update:
	#!/usr/bin/env bash
	export NIX_PATH="nixpkgs=$(nix flake prefetch nixpkgs --json | jq --raw-output '.storePath')"
	cd overlays
	nix-prefetch-git https://github.com/ibhagwan/smartyank.nvim >ibhagwan_smartyank-nvim.json
	nix-prefetch-git https://github.com/stevenblack/hosts >stevenblack_hosts.json
	for pkg in "cicada" "coredns-utils" "flarectl" "xremap" "yamlfmt" "zf"; do
		nix-update --file ./out-of-tree.nix $pkg
	done
	cd ..


setup_pam_u2f:
	pamu2fcfg -opam://homelab

setup_yubikey:
	ykman openpgp keys set-touch sig cached-fixed
