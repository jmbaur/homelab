self: super:
let
  mako-config = super.writeTextFile
    {
      name = "mako-config";
      text = ''
        font=Rec Mono Linear 10
        icon-path=${super.gnome.adwaita-icon-theme}/share/icons/Adwaita
        default-timeout=15000
      '';
    };
in
{
  mako = super.mako.overrideAttrs (old: rec {
    version = "master";
    src = builtins.fetchTarball {
      url = "https://github.com/emersion/mako/archive/1af224eaaab99f44fe7fe9a47a207adecda3569a.tar.gz";
      sha256 = "0af6f92w0d7jwxh67ha5y5cbl45i0vra908ajsjsmpbjl0jmda8r";
    };
    postInstall = ''
      wrapProgram $out/bin/mako \
        --set XCURSOR_THEME "Adwaita" \
        --add-flags "--config=${mako-config}"
    '';
  });
}
