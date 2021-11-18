{ config, lib, pkgs, ... }:
with pkgs;
let
  zig-overlay = callPackage
    (import (builtins.fetchTarball {
      url = "https://github.com/arqv/zig-overlay/archive/84b12f2f19dd90ee170f4966429635beadd5b647.tar.gz";
      sha256 = "1q0cxpnf2x4nwwivmdl6d1il5xmz43ijcv082l77fbvcmk9hlvpy";
    }))
    { };
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
      fdroidcl = super.callPackage ./fdroidcl { };
      git-get = super.callPackage ./git-get { };
      gosee = super.callPackage ./gosee { };
      htmlq = super.callPackage ./htmlq { };
      i3status-rust-wrapped = super.callPackage ./i3status-rust { };
      kanshi-wrapped = super.callPackage ./kanshi { };
      mako-wrapped = super.callPackage ./mako { };
      nix-direnv = super.nix-direnv.override { enableFlakes = true; };
      p = super.callPackage ./p { };
      pa-switch = super.callPackage ./pa-switch { };
      zig = zig;
      zls = super.callPackage ./zls { inherit zig; };
    })
  ];

}
