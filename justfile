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
		.\#neovim \
		.\#neovim-all-languages \
		.\#pomo

update:
	#!/usr/bin/env bash
	export NIX_PATH="nixpkgs=$(nix flake prefetch nixpkgs --json | jq --raw-output '.storePath')"
	for source in $(find -type f -name "*source.json"); do
		args=()
		if [[ $(jq -r ".fetchSubmodules" < "$source") == "true" ]]; then
			args+=("--fetch-submodules")
		fi
		args+=("$(jq -r ".url" < $source)")
		nix-prefetch-git "${args[@]}" > "$source"
	done
