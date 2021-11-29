{ config, pkgs, ... }:
{
  imports = [
    ./ddcci
    ./git
    ./i3
    ./gnome
    ./kitty
    ./neovim
    ./pipewire
    ./sway
    ./tmux
    ./vscode
  ];
}

