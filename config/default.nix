{ config, pkgs, ... }:
{
  imports = [
    ./ddcci
    ./git
    ./neovim
    ./pipewire
    ./sway
    ./tmux
    ./vscode
  ];
}

