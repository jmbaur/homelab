{
  jq,
  lib,
  writeShellApplication,
  zf,
}:

writeShellApplication {
  name = "nixos-kexec";

  runtimeInputs = [
    jq
    zf
  ];

  text =
    ''
      kexec_jq=${./nixos-kexec.jq}
    ''
    + lib.fileContents ./nixos-kexec.bash;
}
