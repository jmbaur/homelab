{ pkgs ? import <nixpkgs> { } }:

let
  newhost = pkgs.writeShellScriptBin "newhost" ''
    set -e
    ORIG_PATH=/etc/nixos
    NEW_PATH=''${PWD}/hosts/''${HOSTNAME}
    if [ ! -d $NEW_PATH ]; then
      mkdir -p $NEW_PATH
    fi
    cp -rf ''${OLD_PATH}/* ''${NEW_PATH}/
    rm -rf ''${OLD_PATH}/*
  '';
in pkgs.mkShell {
  shellHook = ''
    ${(import ./default.nix).pre-commit-check.shellHook}
  '';
  nativeBuildInputs = [ newhost ];
}
