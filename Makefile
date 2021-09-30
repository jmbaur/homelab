.DEFAULT_GOAL := test

host :=$(shell hostname)
config_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))hosts/$(host)/configuration.nix

test:
	NIXOS_CONFIG=${config_path} nixos-rebuild test

switch:
	NIXOS_CONFIG=${config_path} nixos-rebuild switch
	bash configs/setup.sh ${host}
