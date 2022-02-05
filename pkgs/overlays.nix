[
  (self: super: {
    zf = super.callPackage ./zf.nix { };
  })
  (import ./chromium.nix)
  (import ./mako.nix)
  (import ./nix-direnv.nix)
  (self: super: {
    fdroidcl = super.callPackage ./fdroidcl.nix { };
  })
  (self: super: {
    p = self.callPackage ./p.nix { };
  })
]
