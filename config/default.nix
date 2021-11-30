{ config, pkgs, ... }:
{
  imports = [
    ./ddcci
    ./git
    ./i3
    ./gnome
    ./neovim
    ./pipewire
    ./sway
    ./tmux
    ./vscode
  ];
}

