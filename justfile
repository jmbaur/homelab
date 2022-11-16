# vim: ft=make

help:
	@just --list

clean:
	rm -rf result*
	rm -rf $out

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
	pamu2fcfg -opam://homelab

setup_yubikey:
	ykman openpgp keys set-touch sig cached-fixed

uboot_cn9130-cf-pro: clean
	podman build \
		--tag cn913x_build \
		--file misc/cn913x/Containerfile
	mkdir -p $out
	podman run \
		--rm \
		--volume $out:/out:rw \
		cn913x_build

coreboot target: clean
	podman build \
		--tag coreboot_{{target}} \
		--file misc/coreboot/Containerfile \
		misc/coreboot/{{target}}
	mkdir -p $out
	podman run \
		--rm \
		--volume $out:/out:rw \
		coreboot_{{target}}
