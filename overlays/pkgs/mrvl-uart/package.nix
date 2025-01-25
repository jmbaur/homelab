{
  lib,
  lrzsz,
  writeShellApplication,
}:

writeShellApplication {
  name = "mrvl-uart";
  runtimeInputs = [ lrzsz ];
  text = lib.fileContents ./mrvl-uart.bash;
}
