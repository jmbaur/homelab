{ writeShellApplication, fd, fzf, tmux }:
writeShellApplication {
  name = "j";
  runtimeInputs = [ fzf fd tmux ];
  text = builtins.readFile ./j.bash;
}
