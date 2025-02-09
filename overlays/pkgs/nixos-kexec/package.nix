{
  coreutils-full,
  fzf,
  jq,
  lib,
  writeShellApplication,
}:

writeShellApplication {
  name = "nixos-kexec";

  runtimeInputs = [
    coreutils-full
    jq
    fzf
  ];

  text =
    ''
      kexec_jq=${./nixos-kexec.jq}
    ''
    + lib.fileContents ./nixos-kexec.bash;
}
