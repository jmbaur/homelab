self: super: {
  slack = super.slack.overrideAttrs (old: {
    postInstall = ''
      wrapProgram $out/bin/slack \
        --add-flags "--enable-features=WebRTCPipeWireCapturer"
    '';
  });
}
