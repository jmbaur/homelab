self: super: {
  slack = super.symlinkJoin {
    inherit (super.slack) name;
    paths = [ super.slack ];
    buildInputs = [ super.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/slack \
        --add-flags "--enable-features=WebRTCPipeWireCapturer"
    '';
  };
}
