{
  fd,
  fzf,
  gitMinimal,
  tmux,
  writeShellApplication,
}:
writeShellApplication {
  name = "tmux-jump";
  runtimeInputs = [
    fd
    fzf
    gitMinimal
    tmux
  ];
  text = builtins.readFile ./tmux-jump.bash;
}
