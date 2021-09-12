mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

laptop:
	NIXOS_CONFIG=${mkfile_path}/hosts/laptop/configuration.nix nixos-rebuild switch

desktop:
	NIXOS_CONFIG=${PWD}/hosts/desktop/configuration.nix nixos-rebuild switch
