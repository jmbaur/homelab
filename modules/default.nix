{ config, pkgs, ... }:
{
  imports = [
    ./common.nix
    ./git
    ./neovim
    ./tmux
  ];
}

