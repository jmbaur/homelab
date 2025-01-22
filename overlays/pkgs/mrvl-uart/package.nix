{
  lib,
  lrzsz,
  writeShellApplication,
}:

writeShellApplication {
  name = "mrvl-uart";
  runtimeInputs = [ lrzsz ];
  text = lib.readFile ./mrvl-uart.bash;
}
