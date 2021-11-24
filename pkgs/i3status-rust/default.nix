self: super:
let
  config-file = super.writeTextFile {
    name = "i3status-rs-config";
    text = builtins.readFile ./config.toml;
  };
in
{
  i3status-rust = super.symlinkJoin {
    name = "i3status-rust";
    paths = [ super.i3status-rust ];
    buildInputs = [ super.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/i3status-rs --add-flags "${config-file}"
    '';
  };
}
