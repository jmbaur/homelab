{ writeShellScriptBin }:
writeShellScriptBin "caffeine" ''
  time=''${1:-infinity}
  echo "inhibiting idle for $time"
  exec systemd-inhibit --what=idle --who=caffeine --why=Caffeine --mode=block sleep "$time"
''
