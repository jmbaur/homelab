{
  argc,
  coreutils-full,
  fzy,
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
    fzy
    kexec-tools
  ];

  text =
    ''
      kexec_jq=${./nixos-kexec.jq}
    ''
    + lib.fileContents ./nixos-kexec.bash;
}
