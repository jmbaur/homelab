{ writeShellApplication
, fd
, fzf
, tmux
}:
writeShellApplication {
  name = "j";
  runtimeInputs = [ fd fzf tmux ];
  text = builtins.readFile ./j.sh;
}
