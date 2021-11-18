{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  mako-config = writeTextFile
    {
      name = "mako-config";
      text = ''
        icon-path=${pkgs.gnome.adwaita-icon-theme}/share/icons/Adwaita
      '';
    };
in
symlinkJoin {
  name = "mako";
  paths = [ mako ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/mako \
      --add-flags "--config=${mako-config}"
  '';
}
