self: super: {
  i3status-rust = super.symlinkJoin {
    inherit (super.i3status-rust) name;
    paths = [ super.i3status-rust ];
    buildInputs = [ super.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/i3status-rs \
        --add-flags "${super.writeText "i3status-rs-config" (builtins.readFile ./config.toml)}"
    '';
  };
}
