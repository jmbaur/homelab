.DEFAULT_GOAL := build
.PHONY: build profile test switch deploy encrypt

build:
	nix build

profile:
	nix profile upgrade '.#' 0

test:
	nixos-rebuild --flake '.#' test

switch:
	nixos-rebuild --flake '.#' switch

deploy:
	nixops deploy

encrypt:
	find . -name secrets.nix | xargs -n 1 gpg --batch --yes --encrypt --recipient jaredbaur@fastmail.com
