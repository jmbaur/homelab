{ config, pkgs, ... }:
{
  imports = [
    ./common
    ./deploy
    ./git
    ./neovim
    ./tmux
  ];
}

