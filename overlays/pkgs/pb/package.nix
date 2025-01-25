{
  curl,
  lib,
  writeShellApplication,
}:

writeShellApplication {
  name = "pb";
  runtimeInputs = [ curl ];
  text = lib.fileContents ./pb.bash;
}
