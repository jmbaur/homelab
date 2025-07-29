{
  curl,
  jq,
  lib,
  nix,
  systemd,
  writeArgcShellApplication,
}:

writeArgcShellApplication {
  name = "nixos-update";

  runtimeInputs = [
    curl
    jq
    nix
    systemd
  ];

  text = lib.fileContents ./nixos-update.bash;
}
