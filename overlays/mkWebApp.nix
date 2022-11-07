{ chromium, writeShellScriptBin, ... }:
name: url: writeShellScriptBin name ''
  ${chromium}/bin/${chromium.meta.mainProgram} --app=${url}
''
