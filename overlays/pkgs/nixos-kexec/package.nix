{
  writeShellApplication,
  skim,
  jq,
}:
writeShellApplication {
  name = "nixos-kexec";
  runtimeInputs = [
    skim
    jq
  ];
  text = builtins.readFile ./nixos-kexec.bash;
}
