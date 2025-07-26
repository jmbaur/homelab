{
  argc,
  coreutils-full,
  fzf,
  jq,
  kexec-tools,
  lib,
  writeShellApplication,
}:

writeShellApplication {
  name = "nixos-kexec";

  runtimeInputs = [
    argc
    coreutils-full
    jq
    fzf
    kexec-tools
  ];

  text = ''
    kexec_jq=${./nixos-kexec.jq}
  ''
  + lib.fileContents ./nixos-kexec.bash;
}
