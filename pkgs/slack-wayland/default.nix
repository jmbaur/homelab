{ pkgs ? import <nixpkgs> { } }:
pkgs.symlinkJoin {
  name = "slack";
  paths = [ pkgs.slack ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/slack \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--ozone-platform=wayland" \
      --add-flags "--enable-features=WebRTCPipeWireCapturer"
  '';
}
