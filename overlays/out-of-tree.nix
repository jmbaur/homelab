{ pkgs ? import <nixpkgs> { } }: {
  cicada = pkgs.callPackage ./cicada.nix { };
  coredns-utils = pkgs.callPackage ./coredns-utils.nix { };
  depthcharge-tools = pkgs.callPackage ./depthcharge-tools.nix { };
  flarectl = pkgs.callPackage ./flarectl.nix { };
  stevenblack-blocklist = pkgs.callPackage ./stevenblack-blocklist.nix { };
  u-rootInitramfs = pkgs.callPackage ./u-root.nix { };
}
