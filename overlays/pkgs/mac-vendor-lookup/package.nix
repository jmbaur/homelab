{
  coreutils-full,
  curl,
  gawk,
  gnused,
  gzip,
  iproute2,
  writeShellApplication,
}:

writeShellApplication {
  name = "mac-vendor-lookup";
  runtimeInputs = [
    coreutils-full
    curl
    gawk
    gnused
    gzip
    iproute2
  ];
  text = builtins.readFile ./mac-vendor-lookup.bash;
}
