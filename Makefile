.PHONY: test, switch, iso, deploy, encrypt
.DEFAULT_GOAL := test

test:
	nixos-rebuild --flake '.#' test

switch:
	nixos-rebuild --flake '.#' switch

iso:
	nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso/iso.nix

deploy:
	nixops deploy

encrypt:
	find . -name secrets.nix | xargs -n 1 gpg --batch --yes --encrypt --recipient jaredbaur@fastmail.com
