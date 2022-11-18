# vim: ft=make

help:
	@just --list

init:
	mkdir -p $out

clean: init
	rm -rf result*
	rm -rf $out/*

switch:
	nixos-rebuild switch -L --flake .# --use-remote-sudo

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
	nix shell nixpkgs#pam_u2f -c pamu2fcfg -opam://homelab

setup_yubikey:
	nix shell nixpkgs#yubikey-manager -c ykman openpgp keys set-touch sig cached-fixed

# TODO(jared): parametrize ARCH for crossgcc
coreboot_deps:
	podman build \
		--tag coreboot \
		--file misc/coreboot/Containerfile

coreboot target: coreboot_deps clean
	podman run \
		--rm \
		--volume $out:/out:rw \
		--volume $PWD/misc/coreboot/{{target}}:/config:ro \
		coreboot
