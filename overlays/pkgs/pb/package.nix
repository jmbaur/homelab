{
  curl,
  lib,
  writeShellApplication,
}:

writeShellApplication {
  name = "pb";
  runtimeInputs = [ curl ];
  text = lib.readFile ./pb.bash;
}
