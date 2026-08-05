{
  gnugrep,
  iproute2,
  jq,
  lib,
  netcat,
  systemd,
  writeShellApplication,
}:

writeShellApplication {
  name = "ipv6-link-local-ssh-proxy-command";

  runtimeInputs = [
    gnugrep
    iproute2
    jq
    netcat
    systemd
  ];

  text = lib.fileContents ./ipv6-link-local-ssh-proxy-command.bash;
}
