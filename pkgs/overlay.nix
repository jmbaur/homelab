final: prev: {
  c2esp = prev.callPackage ./c2esp.nix { };
  fdroidcl = prev.callPackage ./fdroidcl.nix { };
  j = prev.callPackage ./j.nix { };
  zf = prev.callPackage ./zf.nix { };
}
