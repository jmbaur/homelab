{ config, pkgs, ... }:
{
  imports = [
    ./ddcci
    ./foot
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

