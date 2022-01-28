{ config, pkgs, ... }:
{
  imports = [
    ./common
    ./git
    ./neovim
    ./tmux
  ];
}

