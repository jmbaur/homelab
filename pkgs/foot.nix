self: super:

let
  foot-config = super.writeTextFile {
    name = "foot-config.ini";
    text = ''
      [main]
      font=Iosevka:size=10
      term=xterm-256color
      selection-target=both

      [mouse]
      hide-when-typing=yes

      [cursor]
      color=ffffea 000000

      [colors]
      foreground=000000
      background=ffffea
      regular0=000000
      regular1=ad4f4f
      regular2=468747
      regular3=8f7734
      regular4=268bd2
      regular5=888aca
      regular6=6aa7a8
      regular7=f3f3d3
      bright0=878781
      bright1=ffdddd
      bright2=ebffeb
      bright3=edeea5
      bright4=ebffff
      bright5=96d197
      bright6=a1eeed
      bright7=ffffeb
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
