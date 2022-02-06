[
  (import ./mako.nix)
  (import ./slack.nix)
  (self: super: { fdroidcl = super.callPackage ./fdroidcl.nix { }; })
  (self: super: { p = self.callPackage ./p.nix { }; })
  (self: super: { zf = super.callPackage ./zf.nix { }; })
]
