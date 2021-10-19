{ config, lib, pkgs, ... }:
{
  nixpkgs.overlays =
    [
      (self: super: { proj = super.callPackage ./proj { }; })
    ];
}
