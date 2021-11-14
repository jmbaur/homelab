.PHONY: test, switch, iso
.DEFAULT_GOAL := test

test:
	nixos-rebuild --flake '.#' test

switch:
	nixos-rebuild --flake '.#' switch

iso:
	nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso/iso.nix
