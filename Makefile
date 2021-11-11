.PHONY: configs iso
.DEFAULT_GOAL := test

host :=$(shell hostname)
config_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))hosts/$(host)/configuration.nix

test:
	nixos-rebuild -I nixos-config=${config_path} test

switch:
	nixos-rebuild -I nixos-config=${config_path} switch

iso:
	nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso/iso.nix
