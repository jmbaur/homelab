{ pkgs ? import <nixpkgs> { } }:
pkgs.vimUtils.buildVimPlugin {
  name = "my-vim";
  src = builtins.path { path = ./.; };
}
