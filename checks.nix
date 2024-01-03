inputs:
inputs.nixpkgs.lib.mapAttrs
  (_: pkgs: {
    inherit (pkgs.callPackage ./tests/image.nix { })
      image-simple-immutable
      image-simple-mutable
      # image-luks-encrypted
      ;
  })
  inputs.self.legacyPackages
