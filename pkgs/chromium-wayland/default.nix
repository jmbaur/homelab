{ pkgs ? import <nixpkgs> { } }:
pkgs.symlinkJoin {
  name = "chromium";
  paths = [ pkgs.chromium ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/chromium \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--ozone-platform=wayland" \
  '';
}
