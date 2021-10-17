{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [ pkgs.gnumake ];
  shellHook = ''
    ${(import ./default.nix).pre-commit-check.shellHook}
  '';
}
