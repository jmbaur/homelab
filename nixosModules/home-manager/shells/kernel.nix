{ pkgs ? import <nixpkgs> { }, version ? "latest" }:
let
  linux = pkgs."linuxPackages_${pkgs.lib.replaceStrings ["."] ["_"] version}".kernel;
in
with pkgs;
mkShell {
  inputsFrom = [ linux ];
  nativeBuildInputs = [ pkgconfig ncurses ];
}
