{ pkgs ? import <nixpkgs> { } }:
pkgs.symlinkJoin {
  name = "brave";
  paths = [ pkgs.brave ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/brave \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--ozone-platform=wayland" \
  '';
}
