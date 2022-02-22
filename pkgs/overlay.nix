final: prev: {
  mako = prev.mako.overrideAttrs
    (old: {
      version = "aafbc91";
      src = prev.fetchFromGitHub {
        owner = "emersion";
        repo = "mako";
        rev = "197ce76fa1066d2f48578d54ea152d908191a31c";
        sha256 = "sha256-Y6xs5KB30h2A+XRS1CxkMKUV6hBkNKjSmSHpib1zVYg=";
      };
    });
  slack = prev.symlinkJoin {
    name = "slack-pipewire";
    paths = [ prev.slack ];
    buildInputs = [ prev.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/slack \
        --add-flags "--enable-features=WebRTCPipeWireCapturer"
    '';
  };
  fdroidcl = prev.callPackage ./fdroidcl.nix { };
  p = prev.callPackage ./p.nix { };
  zf = prev.callPackage ./zf.nix { };
  gopls = prev.gopls.override { buildGoModule = prev.buildGo118Module; };
}
