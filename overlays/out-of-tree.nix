{ pkgs ? import <nixpkgs> { } }: {
  cicada = pkgs.callPackage ./cicada.nix { };
  depthcharge-tools = pkgs.callPackage ./depthcharge-tools.nix { };
  stevenblack-blocklist = pkgs.callPackage ./stevenblack-blocklist.nix { };
}
