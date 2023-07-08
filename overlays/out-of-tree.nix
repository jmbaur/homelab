{ pkgs ? import <nixpkgs> { } }: {
  cicada = pkgs.callPackage ./cicada.nix { };
  coredns-utils = pkgs.callPackage ./coredns-utils.nix { };
  depthcharge-tools = pkgs.callPackage ./depthcharge-tools.nix { };
  fdroidcl = pkgs.callPackage ./fdroidcl.nix { };
  flarectl = pkgs.callPackage ./flarectl.nix { };
  stevenblack-blocklist = pkgs.callPackage ./stevenblack-blocklist.nix { };
  u-rootInitramfs = pkgs.callPackage ./u-root.nix { };
  xremap = pkgs.callPackage ./xremap.nix { features = [ "sway" ]; };
  yamlfmt = pkgs.callPackage ./yamlfmt.nix { };
}
