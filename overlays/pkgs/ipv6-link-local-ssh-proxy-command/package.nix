{
  dig,
  gnugrep,
  iproute2,
  jq,
  lib,
  netcat,
  writeShellApplication,
}:

writeShellApplication {
  name = "ipv6-link-local-ssh-proxy-command";

  runtimeInputs = [
    dig
    gnugrep
    iproute2
    jq
    netcat
  ];

  text = lib.fileContents ./ipv6-link-local-ssh-proxy-command.bash;
}
