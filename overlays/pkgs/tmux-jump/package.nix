{
  fd,
  lib,
  fzy,
  tmux,
  writeShellApplication,
}:
writeShellApplication {
  name = "tmux-jump";
  runtimeInputs = [
    fd
    fzy
    tmux
  ];
  text = lib.fileContents ./tmux-jump.bash;
}
