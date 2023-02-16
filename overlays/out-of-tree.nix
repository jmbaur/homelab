{ pkgs ? import <nixpkgs> { } }: {
  cicada = pkgs.callPackage ./cicada.nix { };
  coredns-utils = pkgs.callPackage ./coredns-utils.nix { };
  depthcharge-tools = pkgs.callPackage ./depthcharge-tools.nix { };
  flarectl = pkgs.callPackage ./flarectl.nix { };
  flashrom-cros = pkgs.callPackage ./flashrom-cros.nix { };
  flashrom-dasharo = pkgs.callPackage ./flashrom-dasharo.nix { };
  smartyank-nvim = pkgs.callPackage ./smartyank-nvim.nix { };
  stevenblack-blocklist = pkgs.callPackage ./stevenblack-blocklist.nix { };
  u-rootInitramfs = pkgs.callPackage ./u-root.nix { };
  wezterm = pkgs.darwin.apple_sdk_11_0.callPackage ./wezterm.nix {
    inherit (pkgs.darwin.apple_sdk_11_0.frameworks) Cocoa CoreGraphics Foundation UserNotifications;
  };
  xremap = pkgs.callPackage ./xremap.nix { features = [ "sway" ]; };
  yamlfmt = pkgs.callPackage ./yamlfmt.nix { };
}
