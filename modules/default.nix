{ config, pkgs, ... }:
{
  imports = [
    ./common
    ./deploy
    ./desktop
    ./git
    ./neovim
    ./obs
    ./tmux
    ./virtualisation
  ];
}

