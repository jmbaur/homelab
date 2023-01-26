{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  inputsFrom = [ pkgs.linuxPackages_latest.kernel ];
  nativeBuildInputs = with pkgs; [ pkgconfig ncurses ];
}
