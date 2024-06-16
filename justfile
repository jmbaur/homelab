help:
	just --list

# We don't do `nix-env --set --profile ..` here since we aren't using nix
# profiles to manage the system.
#
# run switch-to-configuration for a nixos system
nixos *ARGS:
	nix shell --extra-experimental-features "nix-command flakes" --print-build-logs {{ARGS}} \
		"{{justfile_directory()}}#nixosConfigurations.$(hostname).config.system.build.toplevel" \
		--command sudo switch-to-configuration test

new-machine name:
	mkdir -p {{justfile_directory()}}/nixos-configurations/{{name}}
	echo '{}' >{{justfile_directory()}}/nixos-configurations/{{name}}/default.nix
	touch {{justfile_directory()}}/nixos-configurations/{{name}}/age.pubkey
	touch flake.nix # trigger direnv to get new .sops.yaml

# update all managed packages, meant to be run in CI
update:
	#!/usr/bin/env bash
	tmp=$(mktemp)
	export NIX_PATH="nixpkgs=$(nix flake prefetch nixpkgs --json | jq --raw-output '.storePath')"
	nix flake update --accept-flake-config 2>&1 1>&- | tee -a $tmp
	for source in $(find -type f -name "*source.json"); do
		args=()
		if [[ $(jq -r ".fetchSubmodules" < "$source") == "true" ]]; then
			args+=("--fetch-submodules")
		fi
		args+=("$(jq -r ".url" < $source)")
		nix-prefetch-git "${args[@]}" | tee "$source" | tee -a $tmp
	done
	for cargo_toml in $(find overlays/pkgs -type f -name "Cargo.toml"); do
		pushd $(dirname $cargo_toml)
		nix develop .#$(basename $(dirname $cargo_toml)) --command cargo update
		popd
	done
	echo '```console' > /tmp/pr-body
	ansifilter < $tmp >> /tmp/pr-body
	echo '```' >> /tmp/pr-body

git_is_clean:
	git diff HEAD --quiet

release bump_type="patch": git_is_clean
	cat {{justfile_directory()}}/.version | xargs semver bump {{bump_type}} | tee {{justfile_directory()}}/.version
	git add {{justfile_directory()}}/.version
	git commit -m "Release $(cat {{justfile_directory()}}/.version)"
	git tag "v$(cat {{justfile_directory()}}/.version)"
