{ pkgs ? import <nixpkgs> { }, version ? "latest" }:
with pkgs;
let
  linux = "linuxPackages_${lib.replaceStrings ["."] ["_"] version}".kernel;
in
mkShell {
  inputsFrom = [ linux ];
  nativeBuildInputs = [ pkgconfig ncurses ];
}
