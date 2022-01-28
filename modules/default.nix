{ config, pkgs, ... }:
{
  imports = [
    ./common
    ./deploy
    ./desktop
    ./git
    ./neovim
    ./tmux
  ];
}

