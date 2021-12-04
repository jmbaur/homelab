.DEFAULT_GOAL := build
.PHONY: build test switch deploy encrypt

profile:
	nix profile upgrade '.#' 0

build:
	nixos-rebuild --flake '.#' build

test:
	nixos-rebuild --flake '.#' test

switch:
	nixos-rebuild --flake '.#' switch

deploy:
	nixops deploy

encrypt:
	find . -name secrets.nix | xargs -n 1 gpg --batch --yes --encrypt --recipient jaredbaur@fastmail.com
