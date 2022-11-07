{ bemenu
, bitwarden-cli
, pinentry-bemenu
, wl-clipboard
, writeShellApplication
, wtype
}:
writeShellApplication {
  name = "bitwarden-bemenu";
  runtimeInputs = [ bemenu bitwarden-cli pinentry-bemenu wl-clipboard wtype ];
  text = builtins.readFile ./bitwarden-bemenu.bash;
}
