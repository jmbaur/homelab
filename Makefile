mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

beetroot:
	NIXOS_CONFIG=${mkfile_path}./hosts/beetroot/configuration.nix nixos-rebuild switch

okra:
	NIXOS_CONFIG=${mkfile_path}./hosts/okra/configuration.nix nixos-rebuild switch
