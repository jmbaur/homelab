{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  mako-config = writeTextFile
    {
      name = "mako-config";
      text = ''
        icon-path=${pkgs.gnome.adwaita-icon-theme}/share/icons/Adwaita
        default-timeout=15
      '';
    };
in
symlinkJoin {
  name = "mako";
  paths = [ mako ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/mako \
      --set XCURSOR_THEME "Adwaita" \
      --add-flags "--config=${mako-config}"
  '';
}
