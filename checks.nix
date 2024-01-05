inputs:
inputs.nixpkgs.lib.mapAttrs
  (_: pkgs: {
    inherit (pkgs.callPackage ./tests/image.nix { })
      image-immutable
      image-mutable
      image-unencrypted
      image-tpm2-encrypted
      ;
  })
  inputs.self.legacyPackages
