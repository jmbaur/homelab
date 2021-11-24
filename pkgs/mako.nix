self: super:
let
  mako-config = super.writeTextFile
    {
      name = "mako-config";
      text = ''
        icon-path=${super.gnome.adwaita-icon-theme}/share/icons/Adwaita
        default-timeout=15000
      '';
    };
in
{
  mako = super.mako.overrideAttrs (old: rec {
    version = "master";
    src = super.fetchFromGitHub {
      owner = "emersion";
      repo = old.pname;
      rev = version;
      sha256 = "sha256-8VwBfzC5OfzdxTCPgKm6SwH9SJhHYel/9Kbxn12uNvA=";
    };
    postInstall = ''
      wrapProgram $out/bin/mako \
        --set XCURSOR_THEME "Adwaita" \
        --add-flags "--config=${mako-config}"
    '';
  });
}
