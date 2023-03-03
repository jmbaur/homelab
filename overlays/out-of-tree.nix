{ pkgs ? import <nixpkgs> { } }: {
  cicada = pkgs.callPackage ./cicada.nix { };
  coredns-utils = pkgs.callPackage ./coredns-utils.nix { };
  depthcharge-tools = pkgs.callPackage ./depthcharge-tools.nix { };
  flarectl = pkgs.callPackage ./flarectl.nix { };
  flashrom-cros = pkgs.callPackage ./flashrom-cros.nix { };
  flashrom-dasharo = pkgs.callPackage ./flashrom-dasharo.nix { };
  smartyank-nvim = pkgs.callPackage ./smartyank-nvim.nix { };
  mini-nvim = pkgs.callPackage ./mini-nvim.nix { };
  stevenblack-blocklist = pkgs.callPackage ./stevenblack-blocklist.nix { };
  u-rootInitramfs = pkgs.callPackage ./u-root.nix { };
  xremap = pkgs.callPackage ./xremap.nix { features = [ "sway" ]; };
  yamlfmt = pkgs.callPackage ./yamlfmt.nix { };
}
