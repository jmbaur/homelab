config_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))hosts/$(shell hostname)/configuration.nix

switch:
	NIXOS_CONFIG=${config_path} nixos-rebuild switch

test:
	NIXOS_CONFIG=${config_path} nixos-rebuild test
