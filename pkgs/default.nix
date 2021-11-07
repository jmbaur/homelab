{ config, lib, pkgs, ... }:
let
  zig-overlay = pkgs.callPackage (import (builtins.fetchTarball "https://github.com/arqv/zig-overlay/archive/84b12f2f19dd90ee170f4966429635beadd5b647.tar.gz")) { };
  zig = zig-overlay.master.latest;
in
{
  nixpkgs.overlays = [
    (import
      (builtins.fetchTarball {
        url = "https://github.com/nix-community/neovim-nightly-overlay/archive/8e6ae6ff52545382ca3c786c64948970cfadfe91.tar.gz";
        sha256 = "1xcg23mfx29q8w2lq0rp05whry0vrzz6k3pjqciqd285vl93xykn";
      }))
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
      zig = zig;
      zls = super.callPackage ./zls { inherit zig; };

    })
  ];

}
