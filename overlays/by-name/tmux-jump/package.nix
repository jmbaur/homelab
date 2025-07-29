{
  coreutils,
  fd,
  fzf,
  gnused,
  lib,
  tmux,
  writeArgcShellApplication,
}:

writeArgcShellApplication {
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
