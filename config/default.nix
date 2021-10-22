{ config, pkgs, ... }:
{
  imports = [
    ./alacritty
    ./ddcci
    ./git
    ./gnome
    ./kitty
    ./neovim
    ./tmux
    ./vscode
  ];
}

