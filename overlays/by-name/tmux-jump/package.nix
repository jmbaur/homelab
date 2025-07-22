{
  coreutils,
  fd,
  fzf,
  gnused,
  lib,
  tmux,
  writeShellApplication,
}:

writeShellApplication {
  name = "tmux-jump";
  runtimeInputs = [
    coreutils
    fd
    fzf
    gnused
    tmux
  ];
  text = lib.fileContents ./tmux-jump.bash;
}
