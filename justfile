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
	touch {{justfile_directory()}}/nixos-configurations/{{name}}/default.nix
	touch {{justfile_directory()}}/nixos-configurations/{{name}}/age.pubkey
	touch {{justfile_directory()}}/flake.nix # trigger direnv to get new .sops.yaml
	direnv allow

git_is_clean:
	git diff HEAD --quiet

release bump_type="patch": git_is_clean
	cat {{justfile_directory()}}/.version | xargs semver bump {{bump_type}} | tee {{justfile_directory()}}/.version
	git add {{justfile_directory()}}/.version
	git commit -m "Release $(cat {{justfile_directory()}}/.version)"
	git tag "v$(cat {{justfile_directory()}}/.version)"
