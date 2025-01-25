{
  coreutils-full,
  curl,
  gawk,
  gnused,
  gzip,
  iproute2,
  lib,
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
  text = lib.fileContents ./mac-vendor-lookup.bash;
}
