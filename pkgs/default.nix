{ config, lib, pkgs, ... }:
{
  nixpkgs.overlays = [
    (self: super: {
      brave-wayland = super.callPackage ./brave-wayland { };
      chromium-wayland = super.callPackage ./chromium-wayland { };
      efm-langserver = super.callPackage ./efm-langserver { };
      fdroidcl = super.callPackage ./fdroidcl { };
      firefox-wayland = super.callPackage ./firefox-wayland { };
      google-chrome-wayland = super.callPackage ./google-chrome-wayland { };
      gosee = super.callPackage ./gosee { };
      htmlq = super.callPackage ./htmlq { };
      p = super.callPackage ./p { };
      pa-switch = super.callPackage ./pa-switch { };
      slack-wayland = super.callPackage ./slack-wayland { };
    })
  ];
}
