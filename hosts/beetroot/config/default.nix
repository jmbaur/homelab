{ config, pkgs, ... }:
{
  imports = [
    ./git
    ./kitty
    ./neovim
    ./tmux
    ./vscode
  ];
}

