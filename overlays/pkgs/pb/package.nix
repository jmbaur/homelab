{
  curl,
  lib,
  qrencode,
  writeShellApplication,
}:

writeShellApplication {
  name = "pb";
  runtimeInputs = [
    curl
    qrencode
  ];
  text = lib.fileContents ./pb.bash;
}
