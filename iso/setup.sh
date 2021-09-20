#!/usr/bin/env bash

pushd $(dirname $0)
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix
