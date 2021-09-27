{ pkgs ? import <nixpkgs> { }, system ? builtins.currentSystem }:
let
  zig-overlay =
    builtins.fetchGit { url = "https://github.com/arqv/zig-overlay"; ref = "main"; };
in
(import zig-overlay { inherit pkgs system; }).master.latest
