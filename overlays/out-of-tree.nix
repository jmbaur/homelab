{ pkgs ? import <nixpkgs> { } }: {
  cicada = pkgs.callPackage ./cicada.nix { };
  coredns-utils = pkgs.callPackage ./coredns-utils.nix { };
  depthcharge-tools = pkgs.callPackage ./depthcharge-tools.nix { };
  flarectl = pkgs.callPackage ./flarectl.nix { };
  flashrom-cros = pkgs.callPackage ./flashrom-cros.nix { };
  smartyank-nvim = pkgs.callPackage ./smartyank-nvim.nix { };
  stevenblack-hosts = pkgs.callPackage ./stevenblack-hosts.nix { };
  u-rootInitramfs = pkgs.callPackage ./u-root.nix { };
  xremap = pkgs.callPackage ./xremap.nix { features = [ "sway" ]; };
  yamlfmt = pkgs.callPackage ./yamlfmt.nix { };
}
