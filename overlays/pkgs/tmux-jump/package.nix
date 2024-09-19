{
  fd,
  gitMinimal,
  skim,
  tmux,
  writeShellApplication,
}:
writeShellApplication {
  name = "tmux-jump";
  runtimeInputs = [
    fd
    gitMinimal
    skim
    tmux
  ];
  text = builtins.readFile ./tmux-jump.bash;
}
