{ config, pkgs, ... }:
{
  imports = [
    ./ddcci
    ./foot
    ./git
    ./gnome
    ./kitty
    ./neovim
    ./pipewire
    ./sway
    ./tmux
    ./vscode
  ];
}

