self: super: {
  slack = super.slack.overrideAttrs (old: {
    postInstall = ''
      wrapProgram $out/bin/slack \
        --add-flags "--ozone-platform=wayland" \
        --add-flags "--enable-features=WebRTCPipeWireCapturer" \
        --add-flags "--enable-features=UseOzonePlatform"
    '';
  });
}
