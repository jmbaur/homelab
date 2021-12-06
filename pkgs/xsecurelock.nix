self: super: {
  xsecurelock = super.symlinkJoin {
    inherit (super.xsecurelock) name;
    paths = [ super.xsecurelock ];
    buildInputs = [ super.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/xsecurelock \
      --set XSECURELOCK_FONT "Rec Mono Linear:size=14"
    '';
  };
}
