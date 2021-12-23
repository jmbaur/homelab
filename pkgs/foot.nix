self: super:

let
  foot-config = super.writeTextFile {
    name = "foot-config.ini";
    text = ''
      [main]
      font=Rec Mono Linear:size=10
      term=xterm-256color
      selection-target=both

      [mouse]
      hide-when-typing=yes

      ${builtins.readFile "${super.foot.src}/themes/gruvbox-dark"}
    '';
  };
in
{
  foot = super.foot.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ super.makeWrapper ];
    postInstall = ''
      ${old.postInstall}
      wrapProgram $out/bin/foot \
        --add-flags "--config=${foot-config}"
    '';
  });
}
