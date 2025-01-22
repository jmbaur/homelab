{
  fd,
  gitMinimal,
  lib,
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
  text = lib.readFile ./tmux-jump.bash;
}
