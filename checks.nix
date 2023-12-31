inputs:
inputs.nixpkgs.lib.mapAttrs
  (_: pkgs: {
    immutable-image = pkgs.callPackage ./tests/immutable-image.nix { };
    mutable-image = pkgs.callPackage ./tests/mutable-image.nix { };
  })
  inputs.self.legacyPackages
