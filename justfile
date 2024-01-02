help:
	just --list

init:
	mkdir -p $out

clean: init
	rm -rf {{justfile_directory()}}/result*
	rm -rf $out/*

bump type="patch":
	cat {{justfile_directory()}}/.version | xargs semver bump {{type}} | tee {{justfile_directory()}}/.version

nixos type="switch":
	nixos-rebuild \
		--print-build-logs \
		--use-remote-sudo \
		--flake {{justfile_directory()}} \
		{{type}}

home:
	hmConfig=$(nix build \
		--no-link \
		--print-out-paths \
		--print-build-logs \
		{{justfile_directory()}}#homeConfigurations.$(whoami)-$(hostname).activationPackage) \
		&& $hmConfig/activate

update:
	#!/usr/bin/env bash
	echo '```console' > /tmp/pr-body
	export NIX_PATH="nixpkgs=$(nix flake prefetch nixpkgs --json | jq --raw-output '.storePath')"
	nix flake update --accept-flake-config 2>&1 | tee -a /tmp/pr-body
	for source in $(find -type f -name "*source.json"); do
		args=()
		if [[ $(jq -r ".fetchSubmodules" < "$source") == "true" ]]; then
			args+=("--fetch-submodules")
		fi
		args+=("$(jq -r ".url" < $source)")
		nix-prefetch-git "${args[@]}" | tee "$source" | tee -a /tmp/pr-body
	done
	echo '```' >> /tmp/pr-body
