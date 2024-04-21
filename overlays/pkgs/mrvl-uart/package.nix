{
  writeShellApplication,
  lrzsz,
  tio,
}:
writeShellApplication {
  name = "mrvl-uart";
  runtimeInputs = [
    lrzsz
    tio
  ];
  text = builtins.readFile ./mrvl-uart.bash;
}
