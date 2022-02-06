{ config, pkgs, ... }:
{
  imports = [
    ./common
    ./deploy
    ./desktop
    ./virtualisation
  ];
}

