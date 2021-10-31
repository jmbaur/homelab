{ pkgs ? import <nixpkgs> { } }:
pkgs.symlinkJoin {
  name = "firefox";
  paths = [ pkgs.firefox ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/firefox \
      --set-default MOZ_ENABLE_WAYLAND 1
  '';
}
