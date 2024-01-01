inputs:
inputs.nixpkgs.lib.mapAttrs
  (_: pkgs: {
    inherit (pkgs.callPackage ./tests/image.nix { }) immutable mutable;
  })
  inputs.self.legacyPackages
