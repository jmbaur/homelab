{ writeShellApplication, curl, wine64 }:
writeShellApplication {
  name = "winbox";
  runtimeInputs = [ curl wine64 ];
  text = ''
    if [ ! -f winbox64.exe ]; then
      curl -L -o winbox64.exe https://mt.lv/winbox64
    fi
    wine64 winbox64.exe
  '';
}
