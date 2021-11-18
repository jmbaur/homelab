{ pkgs ? import <nixpkgs> { } }:
with pkgs;

let
  config-file = writeTextFile {
    name = "i3status-rs-config";
    text = builtins.readFile ./config.toml;
  };
in
symlinkJoin {
  name = "i3status-rust";
  paths = [ i3status-rust ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/i3status-rs \
      --add-flags "${config-file}"
  '';
}
