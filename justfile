# vim: ft=make

docker := env_var_or_default("DOCKER", "docker")

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
	nix build -L \
		.\#cicada \
		.\#coredns-utils \
		.\#flarectl \
		.\#flashrom-cros \
		.\#git-get \
		.\#gobar \
		.\#gosee \
		.\#ipwatch \
		.\#linux_cn913x \
		.\#neovim \
		.\#pd-notify \
		.\#runner-nix \
		.\#ubootCN9130_CF_Pro \
		.\#webauthn-tiny \
		.\#xremap \
		.\#yamlfmt \
		.\#zf

update:
	#!/usr/bin/env bash
	cd {{justfile_directory()}}/overlays
	export NIX_PATH="nixpkgs=$(nix flake prefetch nixpkgs --json | jq --raw-output '.storePath')"
	nix-prefetch-git https://github.com/ibhagwan/smartyank.nvim >ibhagwan_smartyank-nvim.json
	nix-prefetch-git https://github.com/stevenblack/hosts >stevenblack_hosts.json
	# TODO(jared): use `nix eval` overlays/out-of-tree.nix when it doesn't show <LAMBDA> (see https://github.com/NixOS/nix/issues/2678).
	for pkg in "cicada" "coredns-utils" "flarectl" "flashrom-cros" "xremap" "yamlfmt" "zf"; do
		nix-update --file ./out-of-tree.nix $pkg
	done

setup_pam_u2f:
	pamu2fcfg -opam://homelab

setup_yubikey:
	ykman openpgp keys set-touch sig cached-fixed

coreboot_deps arch:
	{{docker}} build \
		--build-arg crossgcc_arch={{arch}} \
		--tag coreboot_{{arch}} \
		--file {{justfile_directory()}}/misc/coreboot/Containerfile

coreboot target arch: clean (coreboot_deps arch)
	{{docker}} run \
		--rm \
		--volume $out:/out:rw \
		--volume {{justfile_directory()}}/misc/coreboot/{{target}}:/config:ro \
		coreboot_{{arch}}
