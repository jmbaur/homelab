{ writeShellApplication, fd, fzf, tmux }:
writeShellApplication {
  name = "tmux-jump";
  runtimeInputs = [ fzf fd tmux ];
  text = builtins.readFile ./tmux-jump.bash;
}
