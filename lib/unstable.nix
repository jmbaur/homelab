{ pkgs ? import <nixpkgs> { } }:
pkgs.callPackage (import (builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/master.tar.gz")) { }
