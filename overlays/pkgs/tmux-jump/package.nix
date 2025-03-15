{
  fd,
  lib,
  fzf,
  tmux,
  writeShellApplication,
}:
writeShellApplication {
  name = "tmux-jump";
  runtimeInputs = [
    fd
    fzf
    tmux
  ];
  text = lib.fileContents ./tmux-jump.bash;
}
