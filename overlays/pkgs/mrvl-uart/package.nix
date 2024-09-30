{ writeShellApplication, lrzsz }:

writeShellApplication {
  name = "mrvl-uart";
  runtimeInputs = [ lrzsz ];
  text = builtins.readFile ./mrvl-uart.bash;
}
