{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  shellHook = ''
    ${(import ./default.nix).pre-commit-check.shellHook}
  '';
}
