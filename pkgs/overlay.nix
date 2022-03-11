final: prev: {
  fdroidcl = prev.callPackage ./fdroidcl.nix { };
  p = prev.callPackage ./p.nix { };
  zf = prev.callPackage ./zf.nix { };
  gopls = prev.gopls.override { buildGoModule = prev.buildGo118Module; };
}
