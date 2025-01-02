{ writeShellApplication, curl }:

writeShellApplication {
  name = "pb";
  runtimeInputs = [ curl ];
  text = builtins.readFile ./pb.bash;
}
