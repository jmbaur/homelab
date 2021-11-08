{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [ git gnumake ];
  shellHook = ''
    ${(import ./default.nix).pre-commit-check.shellHook}
  '';
}
