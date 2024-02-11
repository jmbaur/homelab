help:
	just --list

init:
	mkdir -p $out

clean: init
	rm -rf {{justfile_directory()}}/result*
	rm -rf $out/*

# We don't do `nix-env --set --profile ..` here since we aren't using nix
# profiles to manage the system.
#
# run switch-to-configuration for a nixos system
nixos type="switch":
	nixosConfig=$(nix build \
		--no-link \
		--print-out-paths \
		--print-build-logs \
		{{justfile_directory()}}#nixosConfigurations.$(hostname).config.system.build.toplevel) \
		&& sudo $nixosConfig/bin/switch-to-configuration {{type}}

# activate the latest home-manager configuration
home:
	hmConfig=$(nix build \
		--no-link \
		--print-out-paths \
		--print-build-logs \
		{{justfile_directory()}}#homeConfigurations.$(whoami)-$(hostname).activationPackage) \
		&& $hmConfig/activate

# update all managed packages, meant to be run in CI
update:
	#!/usr/bin/env bash
	tmp=$(mktemp)
	export NIX_PATH="nixpkgs=$(nix flake prefetch nixpkgs --json | jq --raw-output '.storePath')"
	nix flake update --accept-flake-config 2>&1 1>&- | tee $tmp
	for source in $(find -type f -name "*source.json"); do
		args=()
		if [[ $(jq -r ".fetchSubmodules" < "$source") == "true" ]]; then
			args+=("--fetch-submodules")
		fi
		args+=("$(jq -r ".url" < $source)")
		nix-prefetch-git "${args[@]}" | tee "$source" | tee -a $tmp
	done
	ansi2html < $tmp > /tmp/pr-body
