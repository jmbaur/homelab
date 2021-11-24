self: super:
let
  config-file = super.writeTextFile {
    name = "i3status-rs-config";
    text = builtins.readFile ./config.toml;
  };
in
{
  i3status-rust = super.i3status-rust.overrideAttrs (old: {
    postInstall = ''
      wrapProgram $out/bin/i3status-rs \
        --add-flags "${config-file}"
    '';
  });
}
