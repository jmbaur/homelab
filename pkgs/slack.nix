self: super: {
  slack = super.symlinkJoin {
    name = "slack-pipewire";
    paths = [ super.slack ];
    buildInputs = [ super.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/slack \
        --add-flags "--enable-features=WebRTCPipeWireCapturer"
    '';
  };
}
