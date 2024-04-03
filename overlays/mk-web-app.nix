{ chromium, writeShellScriptBin, ... }:
name: url:
writeShellScriptBin name ''
  ${chromium}/bin/${chromium.meta.mainProgram} --app=${url} --user-data-dir="''${XDG_CONFIG_HOME:-$HOME/.config}/chromium-app-${name}"
''
