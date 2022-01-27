{ config, pkgs, ... }:
{
  imports = [
    ./git
    ./neovim
    ./tmux
  ];
}

