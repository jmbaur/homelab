inputs:
inputs.nixpkgs.lib.mapAttrs
  (_: pkgs: {
    immutable-image = pkgs.callPackage ./tests/immutable-image.nix { };
  })
  inputs.self.legacyPackages
