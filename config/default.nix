{ config, pkgs, ... }:
{
  imports = [
    ./ddcci
    ./git
    ./gnome
    ./kitty
    ./neovim
    ./tmux
    ./vscode
  ];
}

