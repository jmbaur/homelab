{ config, lib, pkgs, ... }:
{
  nixpkgs.overlays =
    [
      (import ./proj)
    ];
}
