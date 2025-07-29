{
  coreutils-full,
  fzf,
  jq,
  kexec-tools,
  lib,
  writeArgcShellApplication,
}:

writeArgcShellApplication {
  name = "nixos-kexec";

  runtimeInputs = [
    coreutils-full
    jq
    fzf
    kexec-tools
  ];

  text = ''
    kexec_jq=${./nixos-kexec.jq}
    ${lib.fileContents ./nixos-kexec.bash}
  '';
}
