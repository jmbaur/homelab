{ writeShellApplication
, fd
, skim
, tmux
}:
writeShellApplication {
  name = "j";
  runtimeInputs = [ skim fd tmux ];
  text = builtins.readFile ./j.bash;
}
