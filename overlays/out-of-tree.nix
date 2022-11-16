{ pkgs ? import <nixpkgs> { } }: {
  cicada = pkgs.callPackage ./cicada.nix { };
  coredns-utils = pkgs.callPackage ./coredns-utils.nix { };
  depthcharge-tools = pkgs.callPackage ./depthcharge-tools.nix { };
  flarectl = pkgs.callPackage ./flarectl.nix { };
  xremap = pkgs.callPackage ./xremap.nix { features = [ "sway" ]; };
  yamlfmt = pkgs.callPackage ./yamlfmt.nix { };
  zf = pkgs.callPackage ./zf.nix { };
}
