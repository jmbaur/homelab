help:
	just --list

init:
	mkdir -p $out

clean: init
	rm -rf {{justfile_directory()}}/result*
	rm -rf $out/*

nixos type="switch":
	nixos-rebuild \
		--print-build-logs \
		--use-remote-sudo \
		--flake {{justfile_directory()}} \
		{{type}}

build:
	nix build -L --accept-flake-config \
		.\#cicada \
		.\#coredns-utils \
		.\#flarectl \
		.\#git-get \
		.\#neovim \
		.\#neovim-all-languages \
		.\#pomo

update:
	#!/usr/bin/env bash
	cd {{justfile_directory()}}/overlays
	export NIX_PATH="nixpkgs=$(nix flake prefetch nixpkgs --json | jq --raw-output '.storePath')"
	for source in $(find -type f -name "*source.json"); do
		args=()
		if [[ $(jq -r ".fetchSubmodules" < "$source") == "true" ]]; then
			args+=("--fetch-submodules")
		fi
		args+=("$(jq -r ".url" < $source)")
		nix-prefetch-git "${args[@]}" > "$source"
	done
	for drv in $(nix eval --impure --expr "builtins.attrNames (import ./out-of-tree.nix {})" --json | jq -r ".[]"); do
		nix-update --file ./out-of-tree.nix $drv
	done
