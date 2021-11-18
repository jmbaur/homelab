{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  mako-master = mako.overrideAttrs (old: {
    version = "master";
    src = fetchFromGitHub {
      owner = "emersion";
      repo = old.pname;
      rev = "master";
      sha256 = "sha256-8VwBfzC5OfzdxTCPgKm6SwH9SJhHYel/9Kbxn12uNvA=";
    };
  });
  mako-config = writeTextFile
    {
      name = "mako-config";
      text = ''
        icon-path=${pkgs.gnome.adwaita-icon-theme}/share/icons/Adwaita
        default-timeout=15000
      '';
    };
in
symlinkJoin {
  name = "mako";
  paths = [ mako-master ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/mako \
      --set XCURSOR_THEME "Adwaita" \
      --add-flags "--config=${mako-config}"
  '';
}
