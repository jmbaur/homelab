.DEFAULT_GOAL := test

config_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))hosts/$(shell hostname)/configuration.nix

test:
	NIXOS_CONFIG=${config_path} nixos-rebuild test

switch:
	NIXOS_CONFIG=${config_path} nixos-rebuild switch
	bash configs/setup.sh
