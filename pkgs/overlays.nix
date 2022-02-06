[
  (self: super: {
    zf = super.callPackage ./zf.nix { };
  })
  (import ./mako.nix)
  (self: super: {
    fdroidcl = super.callPackage ./fdroidcl.nix { };
  })
  (self: super: {
    p = self.callPackage ./p.nix { };
  })
]
