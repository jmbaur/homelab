{ config, lib, pkgs, ... }:
with pkgs;
let
  zig-overlay = callPackage (import (builtins.fetchTarball "https://github.com/arqv/zig-overlay/archive/84b12f2f19dd90ee170f4966429635beadd5b647.tar.gz")) { };
  zig = zig-overlay.master.latest;
in
{
  nixpkgs.overlays = [
    (import
      (builtins.fetchTarball {
        url = "https://github.com/nix-community/neovim-nightly-overlay/archive/d93da6ae01cffcaadecc6b1cd119d0f21001bce3.tar.gz";
        sha256 = "04d51s52nddf1669wdvacvm952f7f3m8dpddx4ndnvp9bvdn0nzs";
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
