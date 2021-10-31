{ config, lib, pkgs, ... }:
{
  nixpkgs.overlays = [
    (self: super: {
      chromium-wayland = super.callPackage ./chromium-wayland { };
      efm-langserver = super.callPackage ./efm-langserver { };
      fdroidcl = super.callPackage ./fdroidcl { };
      firefox-wayland = super.callPackage ./firefox-wayland { };
      google-chrome-wayland = super.callPackage ./google-chrome-wayland { };
      gosee = super.callPackage ./gosee { };
      htmlq = super.callPackage ./htmlq { };
      nix-direnv = super.nix-direnv.override { enableFlakes = true; };
      p = super.callPackage ./p { };
      pa-switch = super.callPackage ./pa-switch { };
      slack-wayland = super.callPackage ./slack-wayland { };
    })
  ];
}
