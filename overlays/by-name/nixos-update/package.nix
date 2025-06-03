{
  argc,
  curl,
  jq,
  lib,
  nix,
  systemd,
  writeShellApplication,
}:

writeShellApplication {
  name = "nixos-update";

  runtimeInputs = [
    argc
    curl
    jq
    nix
    systemd
  ];

  text = lib.fileContents ./nixos-update.bash;
}
