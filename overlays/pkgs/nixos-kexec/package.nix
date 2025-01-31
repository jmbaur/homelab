{
  coreutils-full,
  jq,
  lib,
  writeShellApplication,
  zf,
}:

writeShellApplication {
  name = "nixos-kexec";

  runtimeInputs = [
    coreutils-full
    jq
    zf
  ];

  text =
    ''
      kexec_jq=${./nixos-kexec.jq}
    ''
    + lib.fileContents ./nixos-kexec.bash;
}
