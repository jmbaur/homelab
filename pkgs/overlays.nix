[
  (import ./nix-direnv.nix)
  # (import ./zls.nix)

  (self: super: {
    fdroidcl = super.callPackage ./fdroidcl.nix { };
  })

  (self: super: {
    p = self.callPackage ./p.nix { };
  })
]
